# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Apprenticeship
          module Helpers
            class ApprenticeshipEngine
              def initialize
                @apprenticeships = {}
                @sessions        = []
              end

              def create_apprenticeship(skill_name:, domain:, mentor_id:, apprentice_id:)
                return nil if @apprenticeships.size >= ApprenticeshipModel::MAX_APPRENTICESHIPS

                appr = Apprenticeship.new(
                  skill_name:    skill_name,
                  domain:        domain,
                  mentor_id:     mentor_id,
                  apprentice_id: apprentice_id
                )
                @apprenticeships[appr.id] = appr
                appr
              end

              def conduct_session(apprenticeship_id:, method:, success:)
                appr = @apprenticeships[apprenticeship_id]
                return nil unless appr

                appr.learn!(method: method, success: success)
                record_session(apprenticeship_id: apprenticeship_id, method: method, success: success)
                appr
              end

              def recommend_method(apprenticeship_id:)
                appr = @apprenticeships[apprenticeship_id]
                return nil unless appr

                appr.recommended_method
              end

              def graduated_apprenticeships
                @apprenticeships.values.select(&:graduated?)
              end

              def active_apprenticeships
                @apprenticeships.values.reject(&:graduated?)
              end

              def by_mentor(mentor_id:)
                @apprenticeships.values.select { |a| a.mentor_id == mentor_id }
              end

              def by_apprentice(apprentice_id:)
                @apprenticeships.values.select { |a| a.apprentice_id == apprentice_id }
              end

              def by_domain(domain:)
                @apprenticeships.values.select { |a| a.domain == domain }
              end

              def decay_all
                @apprenticeships.each_value(&:decay!)
                @apprenticeships.size
              end

              def get(apprenticeship_id)
                @apprenticeships[apprenticeship_id]
              end

              def count
                @apprenticeships.size
              end

              def sessions
                @sessions.dup
              end

              def to_h
                {
                  total:     @apprenticeships.size,
                  active:    active_apprenticeships.size,
                  graduated: graduated_apprenticeships.size,
                  sessions:  @sessions.size
                }
              end

              private

              def record_session(apprenticeship_id:, method:, success:)
                return if @sessions.size >= ApprenticeshipModel::MAX_SESSIONS

                @sessions << {
                  apprenticeship_id: apprenticeship_id,
                  method:            method,
                  success:           success,
                  recorded_at:       Time.now.utc
                }
                @sessions.shift while @sessions.size > ApprenticeshipModel::MAX_HISTORY
              end
            end
          end
        end
      end
    end
  end
end
