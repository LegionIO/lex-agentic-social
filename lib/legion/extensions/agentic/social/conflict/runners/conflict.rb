# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Conflict
          module Runners
            module Conflict
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def register_conflict(parties:, severity:, description:, **)
                return { error: :invalid_severity, valid: Helpers::Severity::LEVELS } unless Helpers::Severity.valid_level?(severity)

                id = conflict_log.record(parties: parties, severity: severity, description: description)
                conflict = conflict_log.get(id)
                Legion::Logging.info "[conflict] registered: id=#{id[0..7]} severity=#{severity} posture=#{conflict[:posture]} parties=#{parties.join(',')}"
                { conflict_id: id, severity: severity, posture: conflict[:posture] }
              end

              def add_exchange(conflict_id:, speaker:, message:, **)
                result = conflict_log.add_exchange(conflict_id, speaker: speaker, message: message)
                if result
                  Legion::Logging.debug "[conflict] exchange: id=#{conflict_id[0..7]} speaker=#{speaker}"
                  { recorded: true }
                else
                  Legion::Logging.debug "[conflict] exchange failed: id=#{conflict_id[0..7]} not found"
                  { error: :not_found }
                end
              end

              def resolve_conflict(conflict_id:, outcome:, resolution_notes: nil, **)
                conflict = conflict_log.get(conflict_id)
                unless conflict
                  Legion::Logging.debug "[conflict] resolve failed: id=#{conflict_id[0..7]} not found"
                  return { error: :not_found }
                end

                if resolution_notes.nil? && Helpers::LlmEnhancer.available?
                  llm_result = Helpers::LlmEnhancer.suggest_resolution(
                    description: conflict[:description],
                    severity:    conflict[:severity],
                    exchanges:   conflict[:exchanges]
                  )
                  resolution_notes = llm_result[:resolution_notes] if llm_result
                end

                result = conflict_log.resolve(conflict_id, outcome: outcome, resolution_notes: resolution_notes)
                if result
                  Legion::Logging.info "[conflict] resolved: id=#{conflict_id[0..7]} outcome=#{outcome}"
                  { resolved: true, outcome: outcome }
                else
                  Legion::Logging.debug "[conflict] resolve failed: id=#{conflict_id[0..7]} not found"
                  { error: :not_found }
                end
              end

              def get_conflict(conflict_id:, **)
                conflict = conflict_log.get(conflict_id)
                Legion::Logging.debug "[conflict] get: id=#{conflict_id[0..7]} found=#{!conflict.nil?}"
                conflict ? { found: true, conflict: conflict } : { found: false }
              end

              def active_conflicts(**)
                conflicts = conflict_log.active_conflicts
                Legion::Logging.debug "[conflict] active: count=#{conflicts.size}"
                { conflicts: conflicts, count: conflicts.size }
              end

              def check_stale_conflicts(**)
                active = conflict_log.active_conflicts
                stale  = active.select { |c| Time.now.utc - c[:created_at] > Helpers::Severity::STALE_CONFLICT_TIMEOUT }
                stale.each do |c|
                  message = 'conflict marked stale — no resolution after 24h'

                  if Helpers::LlmEnhancer.available?
                    age_hours = (Time.now.utc - c[:created_at]) / 3600.0
                    analysis  = Helpers::LlmEnhancer.analyze_stale_conflict(
                      description:    c[:description],
                      severity:       c[:severity],
                      age_hours:      age_hours,
                      exchange_count: c[:exchanges].size
                    )
                    message = "conflict marked stale — #{analysis[:analysis]} (recommendation: #{analysis[:recommendation]})" if analysis
                  end

                  conflict_log.add_exchange(c[:conflict_id], speaker: :system, message: message)
                end
                stale_ids = stale.map { |c| c[:conflict_id] }
                Legion::Logging.debug "[conflict] stale check: active=#{active.size} stale=#{stale.size}"
                { checked: active.size, stale_count: stale.size, stale_ids: stale_ids }
              end

              def recommended_posture(severity:, **)
                posture = Helpers::Severity.recommended_posture(severity)
                Legion::Logging.debug "[conflict] posture: severity=#{severity} posture=#{posture}"
                { severity: severity, posture: posture }
              end

              private

              def conflict_log
                @conflict_log ||= Helpers::ConflictLog.new
              end
            end
          end
        end
      end
    end
  end
end
