# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Entrainment
          module Runners
            module CognitiveEntrainment
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def create_entrainment_pairing(agent_a:, agent_b:, domain:, **)
                pairing = engine.create_pairing(agent_a: agent_a, agent_b: agent_b, domain: domain)
                log.debug '[cognitive_entrainment] pairing ' \
                          "#{agent_a}<->#{agent_b} domain=#{domain} id=#{pairing.id[0..7]}"
                { success: true, pairing_id: pairing.id, agent_a: agent_a,
                  agent_b: agent_b, domain: domain, synchrony: pairing.synchrony }
              end

              def record_entrainment_interaction(pairing_id:, aligned:, **)
                result = engine.record_interaction(pairing_id: pairing_id, aligned: aligned)
                log.debug '[cognitive_entrainment] interaction ' \
                          "id=#{pairing_id[0..7]} aligned=#{aligned}"
                result
              end

              def pairings_for_agent(agent_id:, **)
                pairings = engine.pairings_for(agent_id: agent_id)
                log.debug '[cognitive_entrainment] pairings_for ' \
                          "agent=#{agent_id} count=#{pairings.size}"
                { success: true, agent_id: agent_id,
                  pairings: pairings.map(&:to_h), count: pairings.size }
              end

              def entrained_partners(agent_id:, **)
                partners = engine.entrained_partners(agent_id: agent_id)
                log.debug '[cognitive_entrainment] entrained_partners ' \
                          "agent=#{agent_id} count=#{partners.size}"
                { success: true, agent_id: agent_id, partners: partners, count: partners.size }
              end

              def strongest_entrainment_pairings(limit: 5, **)
                pairings = engine.strongest_pairings(limit: limit)
                log.debug "[cognitive_entrainment] strongest count=#{pairings.size}"
                { success: true, pairings: pairings.map(&:to_h), count: pairings.size }
              end

              def domain_entrainment(domain:, **)
                pairings = engine.by_domain(domain: domain)
                log.debug "[cognitive_entrainment] domain=#{domain} " \
                          "count=#{pairings.size}"
                { success: true, domain: domain,
                  pairings: pairings.map(&:to_h), count: pairings.size }
              end

              def overall_entrainment_level(**)
                sync = engine.overall_entrainment
                log.debug "[cognitive_entrainment] overall_sync=#{sync.round(3)}"
                { success: true, overall_synchrony: sync,
                  entrained_count: engine.entrained_pairings.size }
              end

              def update_cognitive_entrainment(**)
                engine.drift_all
                pruned = engine.prune_independent
                log.debug "[cognitive_entrainment] drift+prune pruned=#{pruned}"
                { success: true, pruned: pruned }
              end

              def cognitive_entrainment_stats(**)
                stats = engine.to_h
                log.debug '[cognitive_entrainment] stats ' \
                          "total=#{stats[:total_pairings]}"
                { success: true }.merge(stats)
              end

              private

              def engine
                @engine ||= Helpers::EntrainmentEngine.new
              end
            end
          end
        end
      end
    end
  end
end
