# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Mirror
          module Helpers
            class MirrorEngine
              INTENT_MAP = {
                communication:        :inform_or_persuade,
                decision:             :resolve_uncertainty,
                emotional_expression: :signal_internal_state,
                creative_act:         :generate_novelty,
                analytical_task:      :reduce_uncertainty,
                social_interaction:   :build_relationship,
                movement:             :change_position
              }.freeze

              attr_reader :events, :simulations, :resonance_map

              def initialize
                @events        = []
                @simulations   = []
                @resonance_map = Hash.new(Constants::DEFAULT_RESONANCE)
              end

              def observe(agent_id:, action_type:, context: {}, emotional_valence: 0.0)
                event = MirrorEvent.new(
                  agent_id:          agent_id,
                  action_type:       action_type,
                  context:           context,
                  emotional_valence: emotional_valence
                )
                @events << event
                @events.shift while @events.size > Constants::MAX_EVENTS
                event
              end

              def simulate(event, confidence: Constants::SIMULATION_CONFIDENCE_DEFAULT)
                resonance = compute_resonance_for(event)
                outcome   = derive_outcome(event)

                sim = Simulation.new(
                  event_id:            event.id,
                  simulated_outcome:   outcome,
                  confidence:          confidence,
                  emotional_resonance: resonance
                )
                @simulations << sim
                @simulations.shift while @simulations.size > Constants::MAX_SIMULATIONS
                sim
              end

              def record_accuracy(simulation_id, accuracy)
                sim = @simulations.find { |s| s.id == simulation_id }
                return false unless sim

                sim.accuracy_score = accuracy.to_f.clamp(0.0, 1.0)
                true
              end

              def empathic_resonance(agent_id)
                @resonance_map[agent_id].clamp(0.0, 1.0)
              end

              def boost_resonance(agent_id)
                current = @resonance_map[agent_id]
                @resonance_map[agent_id] = (current + Constants::RESONANCE_BOOST).round(10).clamp(0.0, 1.0)
              end

              def decay_resonance(agent_id)
                current = @resonance_map[agent_id]
                @resonance_map[agent_id] = (current - Constants::RESONANCE_DECAY).round(10).clamp(0.0, 1.0)
              end

              def decay_all_resonances
                @resonance_map.each_key { |agent_id| decay_resonance(agent_id) }
              end

              def simulation_accuracy_for(agent_id)
                scored = simulations_for(agent_id).reject { |s| s.accuracy_score.nil? }
                return nil if scored.empty?

                scored.sum(&:accuracy_score) / scored.size.to_f
              end

              def simulations_for(agent_id)
                event_ids = events_for(agent_id).map(&:id)
                @simulations.select { |s| event_ids.include?(s.event_id) }
              end

              def events_for(agent_id)
                @events.select { |e| e.agent_id == agent_id }
              end

              def simulation_history(limit: 20)
                @simulations.last(limit).map(&:to_h)
              end

              def known_agents
                @resonance_map.keys
              end

              private

              def compute_resonance_for(event)
                base      = @resonance_map[event.agent_id]
                valence   = event.emotional_valence.abs
                resonance = (base + (valence * Constants::RESONANCE_BOOST)).round(10)
                resonance.clamp(0.0, 1.0)
              end

              def derive_outcome(event)
                {
                  action_type:      event.action_type,
                  predicted_intent: infer_intent(event),
                  emotional_echo:   event.emotional_valence,
                  context_keys:     event.context.keys
                }
              end

              def infer_intent(event)
                INTENT_MAP.fetch(event.action_type, :unknown_intent)
              end
            end
          end
        end
      end
    end
  end
end
