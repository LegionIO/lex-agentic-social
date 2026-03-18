# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module PerspectiveShifting
          module Helpers
            class PerspectiveView
              attr_reader :id, :situation_id, :perspective_id, :valence,
                          :concerns, :opportunities, :confidence, :created_at

              def initialize(situation_id:, perspective_id:, valence: 0.0,
                             concerns: [], opportunities: [], confidence: 0.5)
                @id             = SecureRandom.uuid
                @situation_id   = situation_id
                @perspective_id = perspective_id
                @valence        = valence.clamp(-1.0, 1.0).round(10)
                @concerns       = Array(concerns)
                @opportunities  = Array(opportunities)
                @confidence     = confidence.clamp(0.0, 1.0).round(10)
                @created_at     = Time.now.utc
              end

              def positive?
                @valence > 0.1
              end

              def negative?
                @valence < -0.1
              end

              def neutral?
                !positive? && !negative?
              end

              def to_h
                {
                  id:             @id,
                  situation_id:   @situation_id,
                  perspective_id: @perspective_id,
                  valence:        @valence,
                  concerns:       @concerns,
                  opportunities:  @opportunities,
                  confidence:     @confidence,
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
