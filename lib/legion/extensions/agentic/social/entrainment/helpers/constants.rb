# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Entrainment
          module Helpers
            module Constants
              MAX_PAIRINGS = 200
              MAX_SIGNALS = 500
              MAX_HISTORY = 300

              DEFAULT_SYNC = 0.0
              SYNC_FLOOR = 0.0
              SYNC_CEILING = 1.0

              COUPLING_RATE = 0.1
              DECOUPLING_RATE = 0.05
              NATURAL_DRIFT = 0.02

              ENTRAINED_THRESHOLD = 0.7
              PARTIAL_THRESHOLD = 0.4

              SYNC_LABELS = {
                (0.8..)     => :locked,
                (0.6...0.8) => :entrained,
                (0.4...0.6) => :partial,
                (0.2...0.4) => :drifting,
                (..0.2)     => :independent
              }.freeze

              SIGNAL_TYPES = %i[rhythm timing phase amplitude].freeze
            end
          end
        end
      end
    end
  end
end
