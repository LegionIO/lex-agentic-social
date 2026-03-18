# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module PerspectiveShifting
          module Helpers
            class Perspective
              attr_reader :id, :name, :perspective_type, :priorities,
                          :expertise_domains, :empathy_level, :bias_toward, :created_at

              def initialize(name:, perspective_type:, priorities: [], expertise_domains: [],
                             empathy_level: Constants::DEFAULT_EMPATHY, bias_toward: nil)
                @id               = SecureRandom.uuid
                @name             = name
                @perspective_type = perspective_type
                @priorities       = Array(priorities)
                @expertise_domains = Array(expertise_domains)
                @empathy_level    = empathy_level.clamp(0.0, 1.0)
                @bias_toward      = bias_toward
                @created_at       = Time.now.utc
              end

              def to_h
                {
                  id:                @id,
                  name:              @name,
                  perspective_type:  @perspective_type,
                  priorities:        @priorities,
                  expertise_domains: @expertise_domains,
                  empathy_level:     @empathy_level.round(10),
                  bias_toward:       @bias_toward,
                  created_at:        @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
