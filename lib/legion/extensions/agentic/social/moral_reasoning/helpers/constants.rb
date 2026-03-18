# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module MoralReasoning
          module Helpers
            module Constants
              MAX_DILEMMAS = 100
              MAX_PRINCIPLES = 50
              MAX_HISTORY = 300

              DEFAULT_WEIGHT    = 0.5
              WEIGHT_FLOOR      = 0.1
              WEIGHT_CEILING    = 1.0
              REINFORCEMENT_RATE = 0.1
              DECAY_RATE        = 0.01

              # Haidt's 6 Moral Foundations
              MORAL_FOUNDATIONS = %i[care fairness loyalty authority sanctity liberty].freeze

              # Kohlberg's 6 Stages (grouped into 3 levels)
              KOHLBERG_STAGES = %i[obedience self_interest conformity law_and_order social_contract universal_ethics].freeze

              KOHLBERG_LEVELS = {
                preconventional:  %i[obedience self_interest],
                conventional:     %i[conformity law_and_order],
                postconventional: %i[social_contract universal_ethics]
              }.freeze

              # Ethical frameworks for dilemma resolution
              ETHICAL_FRAMEWORKS = %i[utilitarian deontological virtue care justice rights].freeze

              # Dilemma severity labels keyed by endless/beginless ranges
              SEVERITY_LABELS = {
                (0.8..)     => :critical,
                (0.6...0.8) => :serious,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :minor,
                (..0.2)     => :trivial
              }.freeze
            end
          end
        end
      end
    end
  end
end
