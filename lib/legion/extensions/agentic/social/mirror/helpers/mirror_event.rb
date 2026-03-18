# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module Mirror
          module Helpers
            class MirrorEvent
              attr_reader :id, :agent_id, :action_type, :context, :emotional_valence, :observed_at

              def initialize(agent_id:, action_type:, context: {}, emotional_valence: 0.0)
                @id               = SecureRandom.uuid
                @agent_id         = agent_id
                @action_type      = normalize_action_type(action_type)
                @context          = context.is_a?(Hash) ? context : {}
                @emotional_valence = emotional_valence.to_f.clamp(-1.0, 1.0)
                @observed_at = Time.now.utc
              end

              def to_h
                {
                  id:                @id,
                  agent_id:          @agent_id,
                  action_type:       @action_type,
                  context:           @context,
                  emotional_valence: @emotional_valence,
                  observed_at:       @observed_at
                }
              end

              private

              def normalize_action_type(action_type)
                sym = action_type.to_sym
                Constants::ACTION_TYPES.include?(sym) ? sym : :unknown
              end
            end
          end
        end
      end
    end
  end
end
