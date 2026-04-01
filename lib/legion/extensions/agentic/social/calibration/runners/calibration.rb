# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Calibration
          module Runners
            module Calibration
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def update_calibration(observation: nil, **)
                return { success: true, skipped: :no_observation } unless observation

                calibration_store.update_baseline(
                  latency: observation[:latency] || 0,
                  length:  observation[:content_length] || 0
                )

                result = calibration_store.evaluate_reaction(observation: observation)
                return { success: true, skipped: :no_advisory } unless result

                { success: true, deltas: result[:deltas], weights: calibration_store.calibration_weights }
              end

              def record_advisory_meta(advisory_id:, advisory_types:, **)
                calibration_store.record_advisory(advisory_id: advisory_id, advisory_types: advisory_types)
                { success: true }
              end

              def detect_explicit_feedback(content:, **)
                feedback = calibration_store.detect_explicit_feedback(content)
                { success: true, feedback: feedback }
              end

              def calibration_weights(**)
                { success: true, weights: calibration_store.calibration_weights }
              end

              def calibration_stats(**)
                {
                  success:        true,
                  weights:        calibration_store.calibration_weights,
                  history_counts: calibration_store.history.transform_values(&:size),
                  dirty:          calibration_store.dirty?
                }
              end

              def sync_partner_knowledge(**)
                results = {}
                results[:preferences] = extract_preferences_via_llm
                results[:promotion] = promote_partner_knowledge
                { success: true, results: results }
              rescue StandardError => e
                { success: false, error: e.message }
              end

              def extract_preferences_via_llm(**)
                return { success: true, skipped: :too_soon } unless should_extract_preferences?
                return { success: true, skipped: :llm_unavailable } unless llm_available?

                traces = retrieve_interaction_traces
                return { success: true, skipped: :insufficient_data } if traces.empty?

                context = summarize_traces(traces)
                prompt = build_preference_prompt(context)
                result = Legion::LLM.ask(message: prompt)
                return { success: false, error: :llm_failed } unless result&.content

                parsed = parse_preference_response(result.content)
                return { success: false, error: :parse_failed } unless parsed

                store_llm_preferences(parsed)
                @last_preference_extraction_at = Time.now.utc
                { success: true, preferences_extracted: parsed.size }
              rescue StandardError => e
                { success: false, error: e.message }
              end

              def promote_partner_knowledge(**)
                return { success: true, skipped: :local_unavailable } unless apollo_local_available?

                total = 0
                Helpers::Constants::PROMOTABLE_TAGS.each do |tags|
                  result = Legion::Apollo::Local.promote_to_global(tags: tags, min_confidence: Helpers::Constants::PROMOTION_MIN_CONFIDENCE)
                  total += result[:promoted] if result[:success]
                end

                { success: true, promoted: total }
              rescue StandardError => e
                { success: false, error: e.message }
              end

              private

              def calibration_store
                @calibration_store ||= Helpers::CalibrationStore.new
              end

              def should_extract_preferences?
                return true if @last_preference_extraction_at.nil?

                (Time.now.utc - @last_preference_extraction_at) > Helpers::Constants::PREFERENCE_EXTRACTION_INTERVAL
              end

              def llm_available?
                defined?(Legion::LLM) && Legion::LLM.started?
              end

              def apollo_local_available?
                defined?(Legion::Apollo::Local) && Legion::Apollo::Local.started?
              end

              def retrieve_interaction_traces
                return [] unless defined?(Legion::Extensions::Agentic::Memory::Trace::Runners::Traces)

                runner = Object.new
                runner.extend(Legion::Extensions::Agentic::Memory::Trace::Runners::Traces)
                result = runner.retrieve_by_domain(domain_tag: 'partner_interaction', limit: 50)
                return [] unless result[:success]

                result[:traces] || []
              rescue StandardError => e
                Legion::Logging.warn("[calibration] retrieve_interaction_traces error: #{e.message}")
                []
              end

              def summarize_traces(traces)
                traces.first(50).map do |t|
                  payload = t[:content_payload] || t[:content] || ''
                  "[#{t[:recorded_at] || t[:created_at]}] #{payload}"
                end.join("\n")
              end

              def build_preference_prompt(context)
                <<~PROMPT
                  Based on these interaction patterns with my partner, what communication preferences can I infer? Consider:
                  - Preferred verbosity (concise/normal/detailed)
                  - Preferred tone (casual/professional/technical)
                  - Preferred format (prose/structured/bullet_points)
                  - Technical depth (high_level/moderate/deep)

                  Interaction summary:
                  #{context}

                  Return ONLY a JSON array of objects, each with: domain (string), value (string), confidence (float 0-1).
                PROMPT
              end

              def parse_preference_response(content)
                json_match = content.match(/\[.*\]/m)
                return nil unless json_match

                Legion::JSON.parse(json_match[0])
              rescue StandardError => e
                Legion::Logging.warn("[calibration] parse_preference_response error: #{e.message}")
                nil
              end

              def store_llm_preferences(preferences)
                return unless apollo_local_available?

                base_tags = %w[partner preference llm_inference]
                preferences.each do |pref|
                  content = Legion::JSON.dump({
                                                'domain'     => pref['domain'],
                                                'value'      => pref['value'],
                                                'source'     => 'llm_inference',
                                                'confidence' => pref['confidence'] || 0.65
                                              })
                  tags = base_tags + ["preference:#{pref['domain']}"]
                  Legion::Apollo::Local.upsert(content: content, tags: tags, confidence: pref['confidence'] || 0.65)
                end
              end
            end
          end
        end
      end
    end
  end
end
