# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Social
          module Helpers
            class SocialGraph
              attr_reader :groups, :reputation_scores, :reciprocity_ledger, :reputation_changes

              def initialize
                @groups = {}
                @reputation_scores = {}
                @reciprocity_ledger = []
                @reputation_changes = []
                @dirty = false
              end

              def dirty?
                @dirty
              end

              def mark_clean!
                @dirty = false
                self
              end

              def clear_reputation_changes!
                @reputation_changes = []
              end

              def to_apollo_entries
                @reputation_scores.map do |agent_id, scores|
                  tags = build_apollo_tags(agent_id)
                  content = Legion::JSON.dump({
                                                agent_id:   agent_id.to_s,
                                                scores:     scores,
                                                updated_at: Time.now.utc.iso8601
                                              })
                  { content: content, tags: tags }
                end
              end

              def from_apollo(store:)
                result = store.query(text: 'social_graph reputation', tags: %w[social_graph reputation])
                return false unless result[:success] && result[:results]&.any?

                result[:results].each { |entry| restore_from_entry(entry) }
                true
              rescue StandardError => e
                Legion::Logging.warn("[social_graph] from_apollo error: #{e.message}")
                false
              end

              def join_group(group_id:, role: :contributor, members: [])
                @groups[group_id] ||= {
                  role:       role,
                  members:    members.dup,
                  joined_at:  Time.now.utc,
                  norms:      [],
                  cohesion:   0.5,
                  violations: []
                }
                trim_groups
                @dirty = true
                @groups[group_id]
              end

              def leave_group(group_id)
                @groups.delete(group_id)
              end

              def update_role(group_id:, role:)
                return nil unless @groups.key?(group_id)
                return nil unless Constants::ROLES.include?(role)

                @groups[group_id][:role] = role
              end

              def update_reputation(agent_id:, dimension:, signal:)
                return nil unless Constants::REPUTATION_DIMENSIONS.key?(dimension)

                @reputation_scores[agent_id] ||= Constants::REPUTATION_DIMENSIONS.keys.to_h { |d| [d, 0.5] }
                current = @reputation_scores[agent_id][dimension]
                new_score = ema(current, signal.clamp(0.0, 1.0), Constants::REPUTATION_ALPHA)
                @reputation_scores[agent_id][dimension] = new_score
                @reputation_changes << { agent_id: agent_id, dimension: dimension, score: new_score }
                @dirty = true
                new_score
              end

              def reputation_for(agent_id)
                scores = @reputation_scores[agent_id]
                return nil unless scores

                composite = 0.0
                Constants::REPUTATION_DIMENSIONS.each do |dim, config|
                  composite += scores[dim] * config[:weight]
                end

                {
                  agent_id:  agent_id,
                  scores:    scores.transform_values { |v| v.round(4) },
                  composite: composite.round(4),
                  standing:  classify_standing(composite)
                }
              end

              def social_standing
                return :neutral if @reputation_scores.empty?

                all_composites = @reputation_scores.map { |id, _| reputation_for(id)[:composite] }
                avg = all_composites.sum / all_composites.size.to_f
                classify_standing(avg)
              end

              def record_reciprocity(agent_id:, action:, direction:)
                @reciprocity_ledger << {
                  agent_id:  agent_id,
                  action:    action,
                  direction: direction,
                  at:        Time.now.utc
                }
                @reciprocity_ledger.shift while @reciprocity_ledger.size > Constants::RECIPROCITY_WINDOW
                @dirty = true
              end

              def reciprocity_balance(agent_id)
                entries = @reciprocity_ledger.select { |e| e[:agent_id] == agent_id }
                given = entries.count { |e| e[:direction] == :given }
                received = entries.count { |e| e[:direction] == :received }

                { given: given, received: received, balance: given - received }
              end

              def record_violation(group_id:, type:, agent_id:)
                return nil unless @groups.key?(group_id)
                return nil unless Constants::NORM_VIOLATIONS.include?(type)

                violation = { type: type, agent_id: agent_id, at: Time.now.utc }
                @groups[group_id][:violations] << violation
                reduce_cohesion(group_id, 0.1)
                violation
              end

              def group_cohesion(group_id)
                return nil unless @groups.key?(group_id)

                @groups[group_id][:cohesion]
              end

              def update_cohesion(group_id:, signal:)
                return nil unless @groups.key?(group_id)

                current = @groups[group_id][:cohesion]
                @groups[group_id][:cohesion] = ema(current, signal.clamp(0.0, 1.0), Constants::REPUTATION_ALPHA)
              end

              def classify_cohesion(group_id)
                cohesion = group_cohesion(group_id)
                return nil unless cohesion

                Constants::COHESION_LEVELS.each do |level, threshold|
                  return level if cohesion >= threshold
                end
                :fractured
              end

              def group_count
                @groups.size
              end

              def agents_tracked
                @reputation_scores.keys.size
              end

              def to_h
                {
                  groups:          @groups.keys,
                  group_count:     @groups.size,
                  agents_tracked:  agents_tracked,
                  social_standing: social_standing,
                  ledger_size:     @reciprocity_ledger.size
                }
              end

              private

              def ema(current, observed, alpha)
                (current * (1.0 - alpha)) + (observed * alpha)
              end

              def classify_standing(composite)
                Constants::STANDING_LEVELS.each do |level, threshold|
                  return level if composite >= threshold
                end
                :ostracized
              end

              def reduce_cohesion(group_id, amount)
                current = @groups[group_id][:cohesion]
                @groups[group_id][:cohesion] = [current - amount, 0.0].max
              end

              def trim_groups
                oldest = @groups.keys.sort_by { |k| @groups[k][:joined_at] }
                oldest.first([@groups.size - Constants::MAX_GROUPS, 0].max).each { |k| @groups.delete(k) }
              end

              def build_apollo_tags(agent_id)
                tags = ['social_graph', 'reputation', agent_id.to_s]
                tags << 'partner' if defined?(Legion::Gaia::BondRegistry) && partner_agent?(agent_id)
                tags
              end

              def partner_agent?(agent_id)
                Legion::Gaia::BondRegistry.partner?(agent_id.to_s)
              rescue StandardError => e
                Legion::Logging.debug("[social_graph] BondRegistry check failed: #{e.message}")
                false
              end

              def restore_from_entry(entry)
                data = Legion::JSON.parse(entry[:content])
                agent_id = data['agent_id'] || data[:agent_id]
                return unless agent_id

                scores = data['scores'] || data[:scores] || {}
                stored = scores.transform_keys(&:to_sym)
                @reputation_scores[agent_id] ||= Constants::REPUTATION_DIMENSIONS.keys.to_h { |d| [d, 0.5] }
                stored.each do |dim, val|
                  @reputation_scores[agent_id][dim] = val.to_f if Constants::REPUTATION_DIMENSIONS.key?(dim)
                end
              rescue StandardError => e
                Legion::Logging.debug("[social_graph] restore entry failed: #{e.message}")
                nil
              end
            end
          end
        end
      end
    end
  end
end
