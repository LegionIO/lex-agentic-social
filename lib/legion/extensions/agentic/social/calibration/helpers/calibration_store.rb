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
                @last_advisory_meta = nil
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

              def record_advisory(advisory_id:, advisory_types:)
                @last_advisory_meta = {
                  advisory_id:    advisory_id,
                  advisory_types: Array(advisory_types).map(&:to_s),
                  timestamp:      Time.now.utc
                }
              end

              def evaluate_reaction(observation:)
                return nil unless @last_advisory_meta
                return nil if @last_advisory_meta[:advisory_types].empty?

                elapsed = Time.now.utc - @last_advisory_meta[:timestamp]
                return nil if elapsed > 3600

                reaction_score = compute_reaction_score(observation)
                confidence = compute_confidence(observation)

                deltas = @last_advisory_meta[:advisory_types].map do |type|
                  apply_delta(type: type, reaction_score: reaction_score, confidence: confidence)
                end

                @last_advisory_meta = nil
                @dirty = true
                { success: true, deltas: deltas }
              end

              def calibration_weights
                @weights.dup
              end

              def detect_explicit_feedback(content)
                text = content.to_s
                return :positive if text.match?(Constants::POSITIVE_PATTERNS)
                return :negative if text.match?(Constants::NEGATIVE_PATTERNS)

                :neutral
              end

              def update_baseline(latency:, length:)
                @partner_baselines['avg_latency'] = if @partner_baselines['avg_latency']
                                                      (@partner_baselines['avg_latency'] * 0.9) + (latency.to_f * 0.1)
                                                    else
                                                      latency.to_f
                                                    end
                @partner_baselines['avg_length'] = if @partner_baselines['avg_length']
                                                     (@partner_baselines['avg_length'] * 0.9) + (length.to_f * 0.1)
                                                   else
                                                     length.to_f
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

              def compute_reaction_score(observation)
                score = 0.0

                feedback = detect_explicit_feedback(observation[:content] || '')
                case feedback
                when :positive then score += Constants::SIGNAL_WEIGHTS[:explicit_feedback]
                when :negative then score -= Constants::SIGNAL_WEIGHTS[:explicit_feedback]
                end

                if @partner_baselines['avg_latency'] && observation[:latency]
                  ratio = observation[:latency].to_f / @partner_baselines['avg_latency']
                  latency_signal = if ratio < 0.8
                                     1.0
                                   else
                                     (ratio > 1.5 ? -1.0 : 0.0)
                                   end
                  score += Constants::SIGNAL_WEIGHTS[:response_latency] * latency_signal
                end

                if @partner_baselines['avg_length'] && observation[:content_length]
                  length_signal = observation[:content_length].to_f / [@partner_baselines['avg_length'], 1].max > 0.5 ? 1.0 : -1.0
                  score += Constants::SIGNAL_WEIGHTS[:message_length] * length_signal
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
