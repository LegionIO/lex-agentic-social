# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module MirrorSystem
          module Helpers
            module Constants
              # Maximum observed behaviors to store
              MAX_OBSERVATIONS = 200

              # Maximum imitation candidates per domain
              MAX_IMITATIONS = 50

              # How quickly observed behaviors are internalized
              MIRROR_ALPHA = 0.15

              # Default resonance strength for new observations
              DEFAULT_RESONANCE = 0.3

              # Minimum resonance to keep an observation
              RESONANCE_FLOOR = 0.05

              # Resonance decay per tick
              RESONANCE_DECAY = 0.01

              # Boost when observation matches own repertoire
              FAMILIARITY_BOOST = 0.2

              # Boost from repeated observation of same behavior
              REPETITION_BOOST = 0.1

              # Maximum resonance value
              MAX_RESONANCE = 1.0

              # Imitation fidelity: how accurately behaviors are copied (0..1)
              DEFAULT_FIDELITY = 0.7

              # Fidelity improvement per successful imitation
              FIDELITY_LEARNING_RATE = 0.05

              # Maximum agents to mirror simultaneously
              MAX_MIRRORED_AGENTS = 20

              # Maximum behaviors in own repertoire
              MAX_REPERTOIRE = 100

              RESONANCE_LABELS = {
                (0.8..)     => :strong_mirror,
                (0.6...0.8) => :resonating,
                (0.4...0.6) => :echoing,
                (0.2...0.4) => :faint,
                (..0.2)     => :silent
              }.freeze
            end
          end
        end
      end
    end
  end
end
