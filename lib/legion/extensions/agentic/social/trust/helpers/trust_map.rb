# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Trust
          module Helpers
            class TrustMap
              attr_reader :entries

              def initialize
                @entries = {} # key: "partner_identity|agent_id:domain"
                @dirty = false
              end

              def dirty?
                @dirty
              end

              def mark_clean!
                @dirty = false
                self
              end

              def get(agent_id, domain: :general, partner_identity: nil)
                @entries[key(agent_id, domain, partner_identity)]
              end

              def get_or_create(agent_id, domain: :general, partner_identity: nil)
                @entries[key(agent_id, domain, partner_identity)] ||= TrustModel.new_trust_entry(agent_id: agent_id, domain: domain).tap do |entry|
                  entry[:partner_identity] = partner_identity.to_s if partner_identity
                end
              end

              def record_interaction(agent_id, positive:, domain: :general, partner_identity: nil)
                entry = get_or_create(agent_id, domain: domain, partner_identity: partner_identity)
                entry[:interaction_count] += 1
                entry[:last_interaction] = Time.now.utc

                if positive
                  entry[:positive_count] += 1
                  TrustModel::TRUST_DIMENSIONS.each do |dim|
                    entry[:dimensions][dim] = TrustModel.clamp(entry[:dimensions][dim] + TrustModel::TRUST_REINFORCEMENT)
                  end
                else
                  entry[:negative_count] += 1
                  TrustModel::TRUST_DIMENSIONS.each do |dim|
                    entry[:dimensions][dim] = TrustModel.clamp(entry[:dimensions][dim] - TrustModel::TRUST_PENALTY)
                  end
                end

                entry[:composite] = TrustModel.composite_score(entry[:dimensions])
                @dirty = true
                entry
              end

              def erase_partner!(identity:)
                prefix = "#{identity}|"
                removed = @entries.keys.select { |k| k.start_with?(prefix) }
                removed.each { |k| @entries.delete(k) }
                @dirty = true if removed.any?
                removed.size
              end

              def reinforce_dimension(agent_id, dimension:, domain: :general, amount: TrustModel::TRUST_REINFORCEMENT, partner_identity: nil)
                entry = get_or_create(agent_id, domain: domain, partner_identity: partner_identity)
                return unless TrustModel::TRUST_DIMENSIONS.include?(dimension)

                entry[:dimensions][dimension] = TrustModel.clamp(entry[:dimensions][dimension] + amount)
                entry[:composite] = TrustModel.composite_score(entry[:dimensions])
                @dirty = true
              end

              def decay_all
                decayed = 0
                @entries.each_value do |entry|
                  TrustModel::TRUST_DIMENSIONS.each do |dim|
                    old = entry[:dimensions][dim]
                    entry[:dimensions][dim] = TrustModel.clamp(old - TrustModel::TRUST_DECAY_RATE)
                  end
                  entry[:composite] = TrustModel.composite_score(entry[:dimensions])
                  decayed += 1
                end
                @dirty = true if decayed.positive?
                decayed
              end

              def trusted_agents(domain: :general, min_trust: TrustModel::TRUST_CONSIDER_THRESHOLD, partner_identity: nil)
                identity = partner_identity&.to_s
                selected = @entries.values.select do |entry|
                  entry[:domain] == domain && entry[:composite] >= min_trust && entry[:partner_identity] == identity
                end
                selected.sort_by! { |entry| -entry[:composite] }
              end

              def delegatable_agents(domain: :general, partner_identity: nil)
                trusted_agents(domain: domain, min_trust: TrustModel::TRUST_DELEGATE_THRESHOLD, partner_identity: partner_identity)
              end

              def count
                @entries.size
              end

              def to_apollo_entries
                @entries.map do |_key, entry|
                  tags = build_apollo_tags(entry[:agent_id], entry[:domain])
                  tags << "partner:#{entry[:partner_identity]}" if entry[:partner_identity]
                  content = Legion::JSON.dump({
                                                agent_id:          entry[:agent_id].to_s,
                                                partner_identity:  entry[:partner_identity],
                                                domain:            entry[:domain].to_s,
                                                dimensions:        entry[:dimensions],
                                                composite:         entry[:composite],
                                                interaction_count: entry[:interaction_count],
                                                positive_count:    entry[:positive_count],
                                                negative_count:    entry[:negative_count],
                                                last_interaction:  entry[:last_interaction]&.iso8601,
                                                created_at:        entry[:created_at]&.iso8601
                                              })
                  { content: content, tags: tags }
                end
              end

              def from_apollo(store:)
                result = store.query(text: 'trust trust_entry', tags: %w[trust trust_entry])
                return false unless result[:success] && result[:results]&.any?

                result[:results].each { |entry| restore_from_entry(entry) }
                true
              rescue StandardError => e
                Legion::Logging.warn("[trust_map] from_apollo error: #{e.message}")
                false
              end

              private

              def key(agent_id, domain, partner_identity = nil)
                base = "#{agent_id}:#{domain}"
                partner_identity ? "#{partner_identity}|#{base}" : base
              end

              def build_apollo_tags(agent_id, domain)
                tags = ['trust', 'trust_entry', agent_id.to_s, domain.to_s]
                tags << 'partner' if defined?(Legion::Gaia::BondRegistry) && partner_agent?(agent_id)
                tags
              end

              def partner_agent?(agent_id)
                Legion::Gaia::BondRegistry.partner?(agent_id.to_s)
              rescue StandardError => e
                Legion::Logging.debug("[trust_map] BondRegistry check failed: #{e.message}")
                false
              end

              def restore_from_entry(entry)
                data = Legion::JSON.parse(entry[:content])
                agent_id = flex(data, 'agent_id')
                return unless agent_id

                domain_val = (flex(data, 'domain') || 'general').to_sym
                dims = restore_dimensions(flex(data, 'dimensions') || {})

                partner_identity = flex(data, 'partner_identity')
                @entries[key(agent_id, domain_val, partner_identity)] = {
                  agent_id:          agent_id,
                  partner_identity:  partner_identity&.to_s,
                  domain:            domain_val,
                  dimensions:        dims,
                  composite:         (flex(data, 'composite') || TrustModel::NEUTRAL_TRUST).to_f,
                  interaction_count: (flex(data, 'interaction_count') || 0).to_i,
                  positive_count:    (flex(data, 'positive_count') || 0).to_i,
                  negative_count:    (flex(data, 'negative_count') || 0).to_i,
                  last_interaction:  parse_time(flex(data, 'last_interaction')),
                  created_at:        parse_time(flex(data, 'created_at')) || Time.now.utc
                }
              rescue StandardError => e
                Legion::Logging.debug("[trust_map] restore entry failed: #{e.message}")
                nil
              end

              def flex(hash, string_key)
                hash[string_key] || hash[string_key.to_sym]
              end

              def restore_dimensions(dims)
                TrustModel::TRUST_DIMENSIONS.to_h do |dim|
                  [dim, (flex(dims, dim.to_s) || TrustModel::NEUTRAL_TRUST).to_f]
                end
              end

              def parse_time(value)
                return nil if value.nil?
                return value if value.is_a?(Time)

                Time.parse(value.to_s)
              rescue ArgumentError => e
                Legion::Logging.debug("[trust_map] parse_time failed: #{e.message}")
                nil
              end
            end
          end
        end
      end
    end
  end
end
