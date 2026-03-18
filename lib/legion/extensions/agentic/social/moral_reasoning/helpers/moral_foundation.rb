# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module MoralReasoning
          module Helpers
            class MoralFoundation
              include Constants

              attr_reader :id, :weight, :sensitivity

              def initialize(id:, weight: DEFAULT_WEIGHT, sensitivity: DEFAULT_WEIGHT)
                @id          = id
                @weight      = weight.clamp(WEIGHT_FLOOR, WEIGHT_CEILING)
                @sensitivity = sensitivity.clamp(0.0, 1.0)
              end

              def reinforce(amount: 1.0)
                @weight = (@weight + (amount * REINFORCEMENT_RATE)).clamp(WEIGHT_FLOOR, WEIGHT_CEILING)
              end

              def weaken(amount: 1.0)
                @weight = (@weight - (amount * REINFORCEMENT_RATE)).clamp(WEIGHT_FLOOR, WEIGHT_CEILING)
              end

              def decay
                @weight = (@weight - DECAY_RATE).clamp(WEIGHT_FLOOR, WEIGHT_CEILING)
              end

              def to_h
                {
                  id:          @id,
                  weight:      @weight,
                  sensitivity: @sensitivity
                }
              end
            end
          end
        end
      end
    end
  end
end
