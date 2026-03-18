# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module SocialLearning
          module Helpers
            module Constants
              MAX_MODELS      = 200
              MAX_BEHAVIORS   = 500
              MAX_OBSERVATIONS = 1000
              MAX_HISTORY = 300

              DEFAULT_PRESTIGE    = 0.5
              PRESTIGE_FLOOR      = 0.0
              PRESTIGE_CEILING    = 1.0
              ATTENTION_THRESHOLD = 0.3
              RETENTION_DECAY     = 0.02
              REPRODUCTION_CONFIDENCE = 0.5
              REINFORCEMENT_BOOST = 0.15
              PUNISHMENT_PENALTY  = 0.2
              PRESTIGE_LEARNING_RATE = 0.1
              STALE_THRESHOLD = 120

              OUTCOME_TYPES   = %i[positive negative neutral].freeze
              LEARNING_STAGES = %i[attention retention reproduction motivation].freeze

              MODEL_LABELS = {
                (0.8..)     => :expert,
                (0.6...0.8) => :proficient,
                (0.4...0.6) => :peer,
                (0.2...0.4) => :novice,
                (..0.2)     => :unreliable
              }.freeze
            end
          end
        end
      end
    end
  end
end
