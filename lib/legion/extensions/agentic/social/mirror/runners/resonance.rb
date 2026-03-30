# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Mirror
          module Runners
            module Resonance
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def empathic_resonance(agent_id:, engine: nil, **)
                eng = engine || mirror_engine
                value = eng.empathic_resonance(agent_id)
                accuracy = eng.simulation_accuracy_for(agent_id)

                empathy_label   = Helpers::Constants.label_for(Helpers::Constants::EMPATHY_LABELS, value)
                resonance_label = Helpers::Constants.label_for(Helpers::Constants::RESONANCE_LABELS, value)

                log.debug "[cognitive_mirror] resonance agent=#{agent_id} " \
                          "value=#{value.round(3)} empathy=#{empathy_label}"

                {
                  success:          true,
                  agent_id:         agent_id,
                  resonance:        value,
                  resonance_label:  resonance_label,
                  empathy_label:    empathy_label,
                  accuracy:         accuracy,
                  event_count:      eng.events_for(agent_id).size,
                  simulation_count: eng.simulations_for(agent_id).size
                }
              end

              def decay_resonances(agent_id: nil, engine: nil, **)
                eng = engine || mirror_engine

                if agent_id
                  eng.decay_resonance(agent_id)
                  after = eng.empathic_resonance(agent_id)
                  log.debug "[cognitive_mirror] resonance decayed agent=#{agent_id} after=#{after.round(3)}"
                  { success: true, agent_id: agent_id, resonance_after: after }
                else
                  eng.decay_all_resonances
                  summary = eng.known_agents.to_h { |id| [id, eng.empathic_resonance(id)] }
                  log.debug "[cognitive_mirror] global resonance decay agents=#{summary.size}"
                  { success: true, agents_decayed: summary.size, resonances: summary }
                end
              end

              def resonance_summary(engine: nil, **)
                eng = engine || mirror_engine
                agents = eng.known_agents

                summary = agents.map do |id|
                  value = eng.empathic_resonance(id)
                  {
                    agent_id:      id,
                    resonance:     value,
                    empathy_label: Helpers::Constants.label_for(Helpers::Constants::EMPATHY_LABELS, value)
                  }
                end

                { success: true, agents: summary, total: agents.size }
              end

              private

              def mirror_engine
                @mirror_engine ||= Helpers::MirrorEngine.new
              end
            end
          end
        end
      end
    end
  end
end
