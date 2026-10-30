# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Calibration
          module Helpers
            class CalibrationStore
              attr_reader :weights, :history

              def initialize
                @weights = Constants::ADVISORY_TYPES.to_h do |type|
                  [type.to_s, Constants::NEUTRAL_SCORE]
                end
                @history = {}
                @pending_advisories = {}
                @evaluated_advisories = {}
                @partner_baselines = { 'avg_latency' => nil, 'avg_length' => nil }
                @dirty = false
              end

              def dirty?
                @dirty
              end

              def mark_clean!
                @dirty = false
                self
              end

              def record_advisory(advisory_id:, advisory_types:, applied: nil, identity: nil)
                return if identity && applied&.dig(:identity) && identity.to_s != applied[:identity].to_s

                expire_advisories!
                return if @evaluated_advisories.key?(advisory_id) || @pending_advisories.key?(advisory_id)

                attribution = (applied || {}).slice(:identity, :exchange_id, :conversation_id).compact
                attribution[:identity] = identity unless identity.nil?
                @pending_advisories[advisory_id] = {
                  advisory_id:    advisory_id,
                  advisory_types: Array(advisory_types).map(&:to_s).uniq,
                  applied:        applied,
                  attribution:    attribution,
                  timestamp:      Time.now.utc
                }
              end

              def evaluate_reaction(observation:)
                expire_advisories!
                candidates = @pending_advisories.values.select { |meta| matches_observation?(meta, observation) }
                return nil unless candidates.one?

                meta = candidates.first
                return nil if meta[:advisory_types].empty?

                reaction_score = compute_reaction_score(observation)
                confidence = compute_confidence(observation)
                deltas = meta[:advisory_types].map do |type|
                  apply_delta(type: type, reaction_score: reaction_score, confidence: confidence)
                end

                @pending_advisories.delete(meta[:advisory_id])
                @evaluated_advisories[meta[:advisory_id]] = meta[:timestamp]
                @dirty = true
                { success: true, deltas: deltas, reaction_score: reaction_score, applied: meta[:applied] }
              end

              def calibration_weights
                @weights.dup
              end

              def detect_explicit_feedback(content)
                text = content.to_s
                return :negative if text.match?(Constants::NEGATIVE_PATTERNS)
                return :positive if text.match?(Constants::POSITIVE_PATTERNS)

                :neutral
              end

              def update_baseline(latency:, length:)
                { 'avg_latency' => latency, 'avg_length' => length }.each do |key, value|
                  next if value.nil?

                  previous = @partner_baselines[key]
                  @partner_baselines[key] = previous ? (previous * 0.9) + (value.to_f * 0.1) : value.to_f
                end
              end

              def to_apollo_entries
                entries = []

                content = Legion::JSON.dump({
                                              'weights'    => @weights,
                                              'baselines'  => @partner_baselines,
                                              'updated_at' => Time.now.utc.iso8601
                                            })
                entries << { content: content, tags: Constants::WEIGHTS_TAGS.dup + ['partner'] }

                @history.each do |type, events|
                  hist_content = Legion::JSON.dump({
                                                     'advisory_type'  => type,
                                                     'events'         => events.last(Constants::MAX_HISTORY),
                                                     'current_weight' => @weights[type]
                                                   })
                  entries << { content: hist_content, tags: Constants::HISTORY_TAG_PREFIX + [type] }
                end

                entries
              end

              def from_apollo(store:)
                result = store.query(text: 'bond calibration weights', tags: Constants::WEIGHTS_TAGS)
                return false unless result[:success] && result[:results]&.any?

                entry = result[:results].first
                parsed = ::JSON.parse(entry[:content])
                @weights.merge!(parsed['weights']) if parsed['weights']
                @partner_baselines = parsed['baselines'] if parsed['baselines']
                true
              rescue StandardError => e
                Legion::Logging.warn("[calibration_store] from_apollo error: #{e.message}")
                false
              end

              private

              def expire_advisories!
                cutoff = Time.now.utc - 3600
                @pending_advisories.delete_if { |_id, meta| meta[:timestamp] < cutoff }
                @evaluated_advisories.delete_if { |_id, timestamp| timestamp < cutoff }
              end

              def matches_observation?(meta, observation)
                return false if observation[:advisory_id] && observation[:advisory_id] != meta[:advisory_id]

                attribution = meta[:attribution]
                return false unless attribution.all? do |key, value|
                  !value.to_s.strip.empty? && observation[key] && observation[key].to_s == value.to_s
                end

                %i[identity exchange_id conversation_id].none? do |key|
                  observation[key] && !attribution.key?(key)
                end
              end

              def compute_reaction_score(observation)
                score = 0.0

                feedback = detect_explicit_feedback(observation[:content] || '')
                return (1.0 + Constants::SIGNAL_WEIGHTS[:explicit_feedback]) / 2.0 if feedback == :positive
                return (1.0 - Constants::SIGNAL_WEIGHTS[:explicit_feedback]) / 2.0 if feedback == :negative

                if @partner_baselines['avg_latency']&.positive? && observation[:latency]
                  ratio = observation[:latency].to_f / @partner_baselines['avg_latency']
                  score += Constants::SIGNAL_WEIGHTS[:response_latency] if ratio < 0.8
                end

                if @partner_baselines['avg_length'] && observation[:content_length]
                  ratio = observation[:content_length].to_f / [@partner_baselines['avg_length'], 1].max
                  score += Constants::SIGNAL_WEIGHTS[:message_length] if ratio > 0.5
                end

                score += Constants::SIGNAL_WEIGHTS[:direct_address] if observation[:direct_address]

                ((score + 1.0) / 2.0).clamp(0.0, 1.0)
              end

              def compute_confidence(observation)
                signals = 0
                signals += 1 if observation[:content].to_s.length.positive?
                signals += 1 if observation[:latency]
                signals += 1 if observation[:content_length]
                signals += 1 if observation.key?(:direct_address)
                (signals / 4.0).clamp(0.2, 1.0)
              end

              def apply_delta(type:, reaction_score:, confidence:)
                delta = (reaction_score - Constants::NEUTRAL_SCORE) * confidence * Constants::EMA_ALPHA
                old_weight = @weights[type] || Constants::NEUTRAL_SCORE
                new_weight = (old_weight + delta).clamp(0.0, 1.0)
                @weights[type] = new_weight

                event = {
                  'reaction_score' => reaction_score.round(3),
                  'confidence'     => confidence.round(3),
                  'delta'          => delta.round(4),
                  'old_weight'     => old_weight.round(3),
                  'new_weight'     => new_weight.round(3),
                  'timestamp'      => Time.now.utc.iso8601
                }

                @history[type] ||= []
                @history[type] << event
                @history[type] = @history[type].last(Constants::MAX_HISTORY)

                {
                  advisory_type:  type,
                  reaction_score: reaction_score.round(3),
                  confidence:     confidence.round(3),
                  delta:          delta.round(4),
                  new_weight:     new_weight.round(3)
                }
              end
            end
          end
        end
      end
    end
  end
end
