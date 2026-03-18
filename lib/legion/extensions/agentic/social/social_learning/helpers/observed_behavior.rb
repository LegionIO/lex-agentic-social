# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module SocialLearning
          module Helpers
            class ObservedBehavior
              include Constants

              attr_reader :id, :model_agent_id, :action, :domain, :context,
                          :outcome, :created_at
              attr_accessor :retention, :reproduced

              def initialize(model_agent_id:, action:, domain:, outcome:, context: {})
                @id             = SecureRandom.uuid
                @model_agent_id = model_agent_id
                @action         = action
                @domain         = domain
                @context        = context
                @outcome        = outcome
                @retention      = 1.0
                @reproduced     = false
                @created_at     = Time.now.utc
              end

              def decay_retention!
                @retention = (@retention - Constants::RETENTION_DECAY).clamp(
                  Constants::PRESTIGE_FLOOR,
                  Constants::PRESTIGE_CEILING
                )
              end

              def retained?
                @retention >= Constants::REPRODUCTION_CONFIDENCE
              end

              def to_h
                {
                  id:             @id,
                  model_agent_id: @model_agent_id,
                  action:         @action,
                  domain:         @domain,
                  context:        @context,
                  outcome:        @outcome,
                  retention:      @retention.round(4),
                  reproduced:     @reproduced,
                  retained:       retained?,
                  created_at:     @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
