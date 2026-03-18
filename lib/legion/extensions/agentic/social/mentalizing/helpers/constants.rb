# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Mentalizing
          module Helpers
            module Constants
              MAX_AGENTS            = 50
              MAX_BELIEFS_PER_AGENT = 30
              MAX_RECURSION_DEPTH   = 4
              BELIEF_DECAY          = 0.02
              BELIEF_FLOOR          = 0.05
              CONFIDENCE_ALPHA      = 0.12
              DEFAULT_CONFIDENCE    = 0.3
              MAX_HISTORY           = 200
              PROJECTION_DISCOUNT   = 0.7

              CONFIDENCE_LABELS = {
                (0.8..)     => :certain,
                (0.6...0.8) => :confident,
                (0.4...0.6) => :uncertain,
                (0.2...0.4) => :speculative,
                (..0.2)     => :unknown
              }.freeze
            end
          end
        end
      end
    end
  end
end
