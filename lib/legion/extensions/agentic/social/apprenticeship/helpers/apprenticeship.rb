# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Apprenticeship
          module Helpers
            class Apprenticeship
              include ApprenticeshipModel

              attr_reader :id, :skill_name, :domain, :mentor_id, :apprentice_id,
                          :mastery, :session_count, :created_at, :last_session_at

              def initialize(skill_name:, domain:, mentor_id:, apprentice_id:)
                data = ApprenticeshipModel.new_apprenticeship(
                  skill_name:    skill_name,
                  domain:        domain,
                  mentor_id:     mentor_id,
                  apprentice_id: apprentice_id
                )
                @id              = data[:id]
                @skill_name      = data[:skill_name]
                @domain          = data[:domain]
                @mentor_id       = data[:mentor_id]
                @apprentice_id   = data[:apprentice_id]
                @mastery         = data[:mastery]
                @session_count   = data[:session_count]
                @created_at      = data[:created_at]
                @last_session_at = data[:last_session_at]
              end

              def current_phase
                ApprenticeshipModel.phase_for(@mastery)
              end

              def mastery_label
                ApprenticeshipModel.mastery_label_for(@mastery)
              end

              def graduated?
                @mastery >= ApprenticeshipModel::MASTERY_THRESHOLD
              end

              def recommended_method
                ApprenticeshipModel.phase_for(@mastery)
              end

              def learn!(method:, success:)
                multiplier = case method
                             when :exploration then ApprenticeshipModel::EXPLORATION_MULTIPLIER
                             when :coaching    then ApprenticeshipModel::COACHING_MULTIPLIER
                             else 1.0
                             end

                gain = success ? ApprenticeshipModel::LEARNING_GAIN * multiplier : 0.0
                @mastery = ApprenticeshipModel.clamp_mastery(@mastery + gain)
                @session_count += 1
                @last_session_at = Time.now.utc
                self
              end

              def decay!
                @mastery = ApprenticeshipModel.clamp_mastery(@mastery - ApprenticeshipModel::DECAY_RATE)
                self
              end

              def to_h
                {
                  id:              @id,
                  skill_name:      @skill_name,
                  domain:          @domain,
                  mentor_id:       @mentor_id,
                  apprentice_id:   @apprentice_id,
                  mastery:         @mastery,
                  current_phase:   current_phase,
                  mastery_label:   mastery_label,
                  graduated:       graduated?,
                  session_count:   @session_count,
                  created_at:      @created_at,
                  last_session_at: @last_session_at
                }
              end
            end
          end
        end
      end
    end
  end
end
