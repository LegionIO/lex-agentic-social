# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Mirror
          module Runners
            module Simulate
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def simulate_action(event_id:, confidence: Helpers::Constants::SIMULATION_CONFIDENCE_DEFAULT,
                                  engine: nil, **)
                eng = engine || mirror_engine

                event = eng.events.find { |e| e.id == event_id }
                unless event
                  log.debug "[cognitive_mirror] simulate_action: event_id=#{event_id} not found"
                  return { success: false, error: 'event not found', event_id: event_id }
                end

                sim = eng.simulate(event, confidence: confidence)
                eng.boost_resonance(event.agent_id)

                confidence_label = Helpers::Constants.label_for(Helpers::Constants::CONFIDENCE_LABELS, sim.confidence)
                log.debug "[cognitive_mirror] simulated event=#{event_id} " \
                          "confidence_tier=#{confidence_label} resonance=#{sim.emotional_resonance.round(3)}"

                { success: true, simulation: sim.to_h, confidence_tier: confidence_label }
              end

              def record_simulation_accuracy(simulation_id:, accuracy:, engine: nil, **)
                eng = engine || mirror_engine
                recorded = eng.record_accuracy(simulation_id, accuracy)

                unless recorded
                  log.debug "[cognitive_mirror] record_accuracy: simulation_id=#{simulation_id} not found"
                  return { success: false, error: 'simulation not found', simulation_id: simulation_id }
                end

                log.debug "[cognitive_mirror] accuracy recorded simulation=#{simulation_id} score=#{accuracy}"
                { success: true, simulation_id: simulation_id, accuracy: accuracy.to_f.clamp(0.0, 1.0) }
              end

              def simulation_history(limit: 20, engine: nil, **)
                eng = engine || mirror_engine
                history = eng.simulation_history(limit: limit)
                { success: true, simulations: history, count: history.size }
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
