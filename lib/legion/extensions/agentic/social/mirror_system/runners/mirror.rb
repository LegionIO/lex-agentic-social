# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module MirrorSystem
          module Runners
            module Mirror
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def observe_behavior(agent_id:, action:, domain:, context: nil, outcome: nil, **)
                obs = mirror_system.observe(agent_id: agent_id, action: action, domain: domain, context: context, outcome: outcome)
                log.debug "[mirror] observe: agent=#{agent_id} action=#{action} domain=#{domain} " \
                          "resonance=#{obs.resonance.round(3)} count=#{obs.observation_count}"
                { success: true, observation: obs.to_h }
              end

              def imitate_behavior(action:, domain:, source_agent: nil, **)
                result = mirror_system.imitate(action: action, domain: domain, source_agent: source_agent)
                if result
                  log.debug "[mirror] imitate: action=#{action} domain=#{domain} " \
                            "fidelity=#{result[:fidelity].round(3)}"
                  {
                    success:   true,
                    imitated:  true,
                    action:    action,
                    domain:    domain,
                    fidelity:  result[:fidelity].round(4),
                    source:    result[:observation].agent_id,
                    resonance: result[:observation].resonance.round(4)
                  }
                else
                  log.debug "[mirror] imitate: action=#{action} domain=#{domain} no_observation"
                  { success: true, imitated: false, action: action, domain: domain }
                end
              end

              def report_imitation_outcome(action:, domain:, success_flag:, **)
                mirror_system.update_fidelity(action: action, domain: domain, success: success_flag)
                fidelity = mirror_system.fidelity_for(action, domain)
                log.debug "[mirror] outcome: action=#{action} domain=#{domain} " \
                          "success=#{success_flag} fidelity=#{fidelity.round(3)}"
                { success: true, action: action, domain: domain, fidelity: fidelity.round(4) }
              end

              def strongest_mirrors(count: 5, **)
                mirrors = mirror_system.strongest_mirrors(count)
                log.debug "[mirror] strongest: count=#{mirrors.size}"
                { success: true, mirrors: mirrors.map(&:to_h), count: mirrors.size }
              end

              def observations_for(agent_id:, **)
                observations = mirror_system.observations_for_agent(agent_id)
                log.debug "[mirror] observations_for: agent=#{agent_id} count=#{observations.size}"
                { success: true, agent_id: agent_id, observations: observations.map(&:to_h), count: observations.size }
              end

              def observations_in(domain:, **)
                observations = mirror_system.observations_in_domain(domain)
                log.debug "[mirror] observations_in: domain=#{domain} count=#{observations.size}"
                { success: true, domain: domain, observations: observations.map(&:to_h), count: observations.size }
              end

              def repertoire_status(**)
                rep = mirror_system.repertoire
                log.debug "[mirror] repertoire: size=#{rep.size}"
                { success: true, repertoire: rep.values, size: rep.size }
              end

              def update_mirror(**)
                mirror_system.decay_all
                log.debug "[mirror] tick: observations=#{mirror_system.observation_count} " \
                          "repertoire=#{mirror_system.repertoire_size} agents=#{mirror_system.mirrored_agents.size}"
                {
                  success:      true,
                  observations: mirror_system.observation_count,
                  repertoire:   mirror_system.repertoire_size,
                  agents:       mirror_system.mirrored_agents.size
                }
              end

              def mirror_stats(**)
                { success: true, stats: mirror_system.to_h }
              end

              private

              def mirror_system
                @mirror_system ||= Helpers::MirrorSystem.new
              end
            end
          end
        end
      end
    end
  end
end
