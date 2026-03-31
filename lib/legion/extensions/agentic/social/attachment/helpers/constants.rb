# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Attachment
          module Helpers
            module Constants
              # Strength computation weights (must sum to 1.0)
              FREQUENCY_WEIGHT            = 0.3
              RECIPROCITY_WEIGHT          = 0.25
              PREDICTION_ACCURACY_WEIGHT  = 0.2
              DIRECT_ADDRESS_WEIGHT       = 0.15
              CHANNEL_CONSISTENCY_WEIGHT  = 0.1

              # Bond lifecycle stages
              BOND_STAGES = %i[initial forming established deep].freeze

              # Attachment style classifications
              ATTACHMENT_STYLES = %i[secure anxious avoidant].freeze

              # Stage progression thresholds
              STAGE_THRESHOLDS = {
                forming:     { interactions: 10,  strength: 0.3 },
                established: { interactions: 50,  strength: 0.5 },
                deep:        { interactions: 200, strength: 0.7 }
              }.freeze

              # Separation tolerance (consecutive prediction misses before anxiety signal)
              BASE_SEPARATION_TOLERANCE = 3
              SEPARATION_TOLERANCE_GROWTH = {
                initial: 0, forming: 1, established: 2, deep: 4
              }.freeze

              # EMA alpha for strength updates
              STRENGTH_ALPHA = 0.15

              # Style derivation thresholds
              STYLE_THRESHOLDS = {
                anxious_frequency_variance: 0.4,
                anxious_reciprocity_imbalance: 0.3,
                avoidant_frequency: 0.2,
                avoidant_direct_address: 0.15
              }.freeze

              # Apollo Local tag prefix
              TAG_PREFIX = %w[bond attachment].freeze
            end
          end
        end
      end
    end
  end
end
