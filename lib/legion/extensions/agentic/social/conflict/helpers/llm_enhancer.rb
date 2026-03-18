# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Conflict
          module Helpers
            module LlmEnhancer
              SYSTEM_PROMPT = <<~PROMPT
                You are the conflict mediation processor for an autonomous AI agent built on LegionIO.
                You analyze disagreements between the agent and human partners, then suggest resolution approaches.
                Be neutral, constructive, and specific. Focus on finding common ground and actionable next steps.
                Do not take sides. Identify the underlying needs behind each position.
              PROMPT

              module_function

              def available?
                defined?(Legion::LLM) && Legion::LLM.respond_to?(:started?) && Legion::LLM.started?
              rescue StandardError
                false
              end

              def suggest_resolution(description:, severity:, exchanges:)
                prompt = build_suggest_resolution_prompt(description: description, severity: severity, exchanges: exchanges)
                response = llm_ask(prompt)
                parse_suggest_resolution_response(response)
              rescue StandardError => e
                Legion::Logging.warn "[conflict:llm] suggest_resolution failed: #{e.message}"
                nil
              end

              def analyze_stale_conflict(description:, severity:, age_hours:, exchange_count:)
                prompt = build_analyze_stale_conflict_prompt(
                  description:    description,
                  severity:       severity,
                  age_hours:      age_hours,
                  exchange_count: exchange_count
                )
                response = llm_ask(prompt)
                parse_analyze_stale_conflict_response(response)
              rescue StandardError => e
                Legion::Logging.warn "[conflict:llm] analyze_stale_conflict failed: #{e.message}"
                nil
              end

              # --- Private helpers ---

              def llm_ask(prompt)
                chat = Legion::LLM.chat
                chat.with_instructions(SYSTEM_PROMPT)
                chat.ask(prompt)
              end
              private_class_method :llm_ask

              def build_suggest_resolution_prompt(description:, severity:, exchanges:)
                exchange_lines = exchanges.map { |e| "[#{e[:speaker]}]: #{e[:message]}" }.join("\n")

                <<~PROMPT
                  Analyze this conflict and suggest a resolution.

                  DESCRIPTION: #{description}
                  SEVERITY: #{severity}
                  EXCHANGE HISTORY (#{exchanges.size} exchanges):
                  #{exchange_lines}

                  Suggest a constructive resolution approach.

                  Format EXACTLY as:
                  OUTCOME: resolved | deferred | escalated
                  NOTES: <2-3 sentences describing the resolution approach and next steps>
                PROMPT
              end
              private_class_method :build_suggest_resolution_prompt

              def parse_suggest_resolution_response(response)
                return nil unless response&.content

                text = response.content
                outcome_match = text.match(/OUTCOME:\s*(resolved|deferred|escalated)/i)
                notes_match   = text.match(/NOTES:\s*(.+)/im)

                return nil unless outcome_match && notes_match

                outcome = outcome_match.captures.first.strip.downcase.to_sym
                notes   = notes_match.captures.first.strip

                { resolution_notes: notes, suggested_outcome: outcome }
              end
              private_class_method :parse_suggest_resolution_response

              def build_analyze_stale_conflict_prompt(description:, severity:, age_hours:, exchange_count:)
                <<~PROMPT
                  A conflict has been unresolved for #{age_hours.round(1)} hours with #{exchange_count} exchanges.

                  DESCRIPTION: #{description}
                  SEVERITY: #{severity}

                  Recommend how to proceed with this stale conflict.

                  Format EXACTLY as:
                  RECOMMENDATION: escalate | retry | close
                  ANALYSIS: <2-3 sentences explaining the recommendation>
                PROMPT
              end
              private_class_method :build_analyze_stale_conflict_prompt

              def parse_analyze_stale_conflict_response(response)
                return nil unless response&.content

                text = response.content
                rec_match      = text.match(/RECOMMENDATION:\s*(escalate|retry|close)/i)
                analysis_match = text.match(/ANALYSIS:\s*(.+)/im)

                return nil unless rec_match && analysis_match

                recommendation = rec_match.captures.first.strip.downcase.to_sym
                analysis       = analysis_match.captures.first.strip

                { analysis: analysis, recommendation: recommendation }
              end
              private_class_method :parse_analyze_stale_conflict_response
            end
          end
        end
      end
    end
  end
end
