# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module Apprenticeship
          module Helpers
            module ApprenticeshipModel
              # Capacity limits
              MAX_APPRENTICESHIPS = 100
              MAX_SESSIONS        = 500
              MAX_HISTORY         = 300

              # Mastery defaults and bounds
              DEFAULT_MASTERY  = 0.1
              MASTERY_FLOOR    = 0.0
              MASTERY_CEILING  = 1.0
              MASTERY_THRESHOLD = 0.85
              PHASE_THRESHOLD   = 0.5

              # Learning dynamics
              LEARNING_GAIN            = 0.08
              COACHING_MULTIPLIER      = 1.5
              EXPLORATION_MULTIPLIER   = 2.0
              DECAY_RATE               = 0.01

              # Collins' six instructional methods
              METHODS = %i[modeling coaching scaffolding articulation reflection exploration].freeze

              # Phase labels derived from mastery range
              PHASE_LABELS = {
                (0.0...0.2)   => :modeling,
                (0.2...0.4)   => :coaching,
                (0.4...0.6)   => :scaffolding,
                (0.6...0.75)  => :articulation,
                (0.75...0.85) => :reflection,
                (0.85..1.0)   => :exploration
              }.freeze

              # Mastery level labels
              MASTERY_LABELS = {
                (0.8..)     => :expert,
                (0.6...0.8) => :proficient,
                (0.4...0.6) => :intermediate,
                (0.2...0.4) => :apprentice,
                (..0.2)     => :novice
              }.freeze

              module_function

              def phase_for(mastery)
                PHASE_LABELS.each do |range, phase|
                  return phase if range.cover?(mastery)
                end
                :exploration
              end

              def mastery_label_for(mastery)
                MASTERY_LABELS.each do |range, label|
                  return label if range.cover?(mastery)
                end
                :expert
              end

              def clamp_mastery(value)
                value.clamp(MASTERY_FLOOR, MASTERY_CEILING)
              end

              def new_apprenticeship(skill_name:, domain:, mentor_id:, apprentice_id:)
                now = Time.now.utc
                {
                  id:              SecureRandom.uuid,
                  skill_name:      skill_name,
                  domain:          domain,
                  mentor_id:       mentor_id,
                  apprentice_id:   apprentice_id,
                  mastery:         DEFAULT_MASTERY,
                  current_phase:   phase_for(DEFAULT_MASTERY),
                  session_count:   0,
                  created_at:      now,
                  last_session_at: nil
                }
              end
            end
          end
        end
      end
    end
  end
end
