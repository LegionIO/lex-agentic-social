# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module Conflict
          module Helpers
            class ConflictLog
              MAX_CONFLICTS = 1000
              RESOLVED_RETENTION_DAYS = 30

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

              def evict
                evict_expired_resolved
                evict_overflow
              end

              private

              def evict_expired_resolved
                cutoff = Time.now.utc - (RESOLVED_RETENTION_DAYS * 86_400)
                @conflicts.reject! do |_id, conflict|
                  conflict[:status] == :resolved && conflict[:resolved_at] && conflict[:resolved_at] < cutoff
                end
              end

              def evict_overflow
                return if @conflicts.size <= MAX_CONFLICTS

                # Evict oldest resolved conflicts first, then oldest active
                resolved = @conflicts.select { |_, c| c[:status] == :resolved }
                active   = @conflicts.select { |_, c| c[:status] == :active }

                # Remove oldest resolved until under limit
                resolved.sort_by { |_, c| c[:resolved_at] || c[:created_at] }
                        .first(resolved.size - 50)
                        .each_key { |id| @conflicts.delete(id) }
                return if @conflicts.size <= MAX_CONFLICTS

                # Still over? Remove oldest active
                active.sort_by { |_, c| c[:created_at] }
                      .first(active.size - 10)
                      .each_key { |id| @conflicts.delete(id) }
              end
            end
          end
        end
      end
    end
  end
end
