# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module Mirror
          module Helpers
            class Simulation
              attr_reader :id, :event_id, :simulated_outcome, :confidence, :emotional_resonance, :simulated_at
              attr_accessor :accuracy_score

              def initialize(event_id:, simulated_outcome:, confidence: Constants::SIMULATION_CONFIDENCE_DEFAULT,
                             emotional_resonance: Constants::DEFAULT_RESONANCE)
                @id                  = SecureRandom.uuid
                @event_id            = event_id
                @simulated_outcome   = simulated_outcome
                @confidence          = confidence.to_f.clamp(0.0, 1.0)
                @emotional_resonance = emotional_resonance.to_f.clamp(0.0, 1.0)
                @simulated_at        = Time.now.utc
                @accuracy_score      = nil
              end

              def to_h
                {
                  id:                  @id,
                  event_id:            @event_id,
                  simulated_outcome:   @simulated_outcome,
                  confidence:          @confidence,
                  emotional_resonance: @emotional_resonance,
                  simulated_at:        @simulated_at,
                  accuracy_score:      @accuracy_score
                }
              end
            end
          end
        end
      end
    end
  end
end
