# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Entrainment
          module Helpers
            class EntrainmentEngine
              include Constants

              attr_reader :history

              def initialize
                @pairings = {}
                @history  = []
              end

              def create_pairing(agent_a:, agent_b:, domain:)
                evict_oldest if @pairings.size >= MAX_PAIRINGS

                existing = find_pairing(agent_a: agent_a, agent_b: agent_b, domain: domain)
                return existing if existing

                pairing = Pairing.new(agent_a: agent_a, agent_b: agent_b, domain: domain)
                @pairings[pairing.id] = pairing
                record_history(:created, pairing.id)
                pairing
              end

              def record_interaction(pairing_id:, aligned:)
                pairing = @pairings[pairing_id]
                return { success: false, reason: :not_found } unless pairing

                pairing.interact!(aligned: aligned)
                record_history(:interacted, pairing_id)
                {
                  success:    true,
                  synchrony:  pairing.synchrony,
                  entrained:  pairing.entrained?,
                  sync_label: pairing.sync_label
                }
              end

              def pairings_for(agent_id:)
                @pairings.values.select { |p| p.involves?(agent_id) }
              end

              def entrained_pairings
                @pairings.values.select(&:entrained?)
              end

              def entrained_partners(agent_id:)
                pairings_for(agent_id: agent_id)
                  .select(&:entrained?)
                  .map { |p| p.partner_of(agent_id) }
              end

              def strongest_pairings(limit: 5)
                @pairings.values.sort_by { |p| -p.synchrony }.first(limit)
              end

              def by_domain(domain:)
                @pairings.values.select { |p| p.domain == domain }
              end

              def overall_entrainment
                return 0.0 if @pairings.empty?

                @pairings.values.sum(&:synchrony) / @pairings.size
              end

              def drift_all
                @pairings.each_value(&:drift!)
              end

              def prune_independent
                ids = @pairings.select { |_id, p| p.synchrony <= 0.02 }.keys
                ids.each { |id| @pairings.delete(id) }
                ids.size
              end

              def to_h
                {
                  total_pairings:  @pairings.size,
                  entrained_count: entrained_pairings.size,
                  overall_sync:    overall_entrainment,
                  history_count:   @history.size
                }
              end

              private

              def find_pairing(agent_a:, agent_b:, domain:)
                @pairings.values.find do |p|
                  p.domain == domain && pair_match?(p, agent_a, agent_b)
                end
              end

              def pair_match?(pairing, agent_a, agent_b)
                (pairing.agent_a == agent_a && pairing.agent_b == agent_b) ||
                  (pairing.agent_a == agent_b && pairing.agent_b == agent_a)
              end

              def evict_oldest
                oldest_id = @pairings.min_by { |_id, p| p.last_interaction_at }&.first
                @pairings.delete(oldest_id) if oldest_id
              end

              def record_history(event, pairing_id)
                @history << { event: event, pairing_id: pairing_id, at: Time.now.utc }
                @history.shift while @history.size > MAX_HISTORY
              end
            end
          end
        end
      end
    end
  end
end
