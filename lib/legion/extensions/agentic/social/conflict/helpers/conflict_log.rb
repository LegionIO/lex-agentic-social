# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module Conflict
          module Helpers
            class ConflictLog
              attr_reader :conflicts

              def initialize
                @conflicts = {}
              end

              def record(parties:, severity:, description:, posture: nil)
                id = SecureRandom.uuid
                @conflicts[id] = {
                  conflict_id: id,
                  parties:     parties,
                  severity:    severity,
                  posture:     posture || Severity.recommended_posture(severity),
                  description: description,
                  status:      :active,
                  outcome:     nil,
                  created_at:  Time.now.utc,
                  resolved_at: nil,
                  exchanges:   []
                }
                id
              end

              def add_exchange(conflict_id, speaker:, message:)
                conflict = @conflicts[conflict_id]
                return nil unless conflict

                conflict[:exchanges] << { speaker: speaker, message: message, at: Time.now.utc }
              end

              def resolve(conflict_id, outcome:, resolution_notes: nil)
                conflict = @conflicts[conflict_id]
                return nil unless conflict

                conflict[:status] = :resolved
                conflict[:outcome] = outcome
                conflict[:resolution_notes] = resolution_notes
                conflict[:resolved_at] = Time.now.utc
                conflict
              end

              def active_conflicts
                @conflicts.values.select { |c| c[:status] == :active }
              end

              def get(conflict_id)
                @conflicts[conflict_id]
              end

              def count
                @conflicts.size
              end
            end
          end
        end
      end
    end
  end
end
