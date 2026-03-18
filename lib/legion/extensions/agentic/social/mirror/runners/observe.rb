# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Mirror
          module Runners
            module Observe
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def observe_action(agent_id:, action_type:, context: {}, emotional_valence: 0.0, engine: nil, **)
                eng = engine || mirror_engine

                unless Helpers::Constants::ACTION_TYPES.include?(action_type.to_sym)
                  Legion::Logging.debug "[cognitive_mirror] unknown action_type=#{action_type}, mapping to :unknown"
                end

                event = eng.observe(
                  agent_id:          agent_id,
                  action_type:       action_type,
                  context:           context,
                  emotional_valence: emotional_valence
                )

                resonance_label = Helpers::Constants.label_for(Helpers::Constants::RESONANCE_LABELS,
                                                               eng.empathic_resonance(agent_id))
                Legion::Logging.debug "[cognitive_mirror] observed action=#{event.action_type} " \
                                      "agent=#{agent_id} resonance_tier=#{resonance_label}"

                { success: true, event: event.to_h, resonance_tier: resonance_label }
              end

              def list_events(agent_id: nil, engine: nil, **)
                eng = engine || mirror_engine
                events = agent_id ? eng.events_for(agent_id) : eng.events
                { success: true, events: events.map(&:to_h), count: events.size }
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
