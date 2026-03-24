# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module MoralReasoning
          module Helpers
            module LlmEnhancer
              SYSTEM_PROMPT = <<~PROMPT
                You are the moral reasoning engine for an autonomous AI agent built on LegionIO.
                You apply ethical frameworks to evaluate actions and resolve dilemmas.
                Be rigorous, analytical, and fair. Consider multiple perspectives.
                Output structured reasoning, not opinions. Be concise.
              PROMPT

              module_function

              def available?
                !!(defined?(Legion::LLM) && Legion::LLM.respond_to?(:started?) && Legion::LLM.started?)
              rescue StandardError
                false
              end

              def evaluate_action(action:, description:, foundations:)
                response = llm_ask(build_evaluate_action_prompt(action: action, description: description,
                                                                foundations: foundations))
                parse_evaluate_action_response(response)
              rescue StandardError => e
                Legion::Logging.warn "[moral_reasoning:llm] evaluate_action failed: #{e.message}"
                nil
              end

              def resolve_dilemma(dilemma_description:, options:, framework:)
                response = llm_ask(build_resolve_dilemma_prompt(dilemma_description: dilemma_description,
                                                                options: options, framework: framework))
                parse_resolve_dilemma_response(response)
              rescue StandardError => e
                Legion::Logging.warn "[moral_reasoning:llm] resolve_dilemma failed: #{e.message}"
                nil
              end

              def llm_ask(prompt)
                if pipeline_available?
                  response = Legion::LLM::Pipeline::GaiaCaller.chat(
                    message: prompt,
                    phase:   'moral_reasoning',
                    caller:  { extension: 'lex-agentic-social', mode: :moral_reasoning }
                  )
                  content = response&.message&.dig(:content)
                  ::Struct.new(:content).new(content) if content
                else
                  chat = Legion::LLM.chat
                  chat.with_instructions(SYSTEM_PROMPT)
                  chat.ask(prompt)
                end
              end
              private_class_method :llm_ask

              def pipeline_available?
                !!(defined?(Legion::LLM::Pipeline::GaiaCaller) &&
                   Legion::LLM.respond_to?(:pipeline_enabled?) &&
                   Legion::LLM.pipeline_enabled?)
              rescue StandardError
                false
              end
              private_class_method :pipeline_available?

              def build_evaluate_action_prompt(action:, description:, foundations:)
                foundation_lines = foundations.map { |name, strength| "  #{name}: #{strength.round(3)}" }.join("\n")
                desc = description.to_s.empty? ? 'no description' : description
                <<~PROMPT
                  Evaluate this action using moral foundations theory.

                  ACTION: #{action}
                  DESCRIPTION: #{desc}

                  Current foundation strengths:
                  #{foundation_lines}

                  For each foundation, estimate the moral impact of this action (-1.0 to 1.0).
                  Negative = harmful to that foundation, Positive = reinforces that foundation.

                  Format EXACTLY as:
                  REASONING: <1-2 paragraph analysis>
                  IMPACT: care=<float> | fairness=<float> | loyalty=<float> | authority=<float> | sanctity=<float> | liberty=<float>
                PROMPT
              end
              private_class_method :build_evaluate_action_prompt

              def parse_evaluate_action_response(response)
                return nil unless response&.content

                text            = response.content
                reasoning_match = text.match(/REASONING:\s*(.+?)(?=\nIMPACT:|\z)/im)
                impact_match    = text.match(/IMPACT:\s*(.+)/i)
                return nil unless reasoning_match && impact_match

                foundation_impacts = parse_impact_string(impact_match.captures.first.strip)
                return nil if foundation_impacts.empty?

                { reasoning: reasoning_match.captures.first.strip, foundation_impacts: foundation_impacts }
              end
              private_class_method :parse_evaluate_action_response

              def parse_impact_string(impact_str)
                impact_str.split('|').each_with_object({}) do |pair, hash|
                  key, val = pair.strip.split('=')
                  hash[key.strip.to_sym] = val.strip.to_f.clamp(-1.0, 1.0) if key && val
                end
              end
              private_class_method :parse_impact_string

              def build_resolve_dilemma_prompt(dilemma_description:, options:, framework:)
                option_lines = options.map do |opt|
                  foundations_str = opt.fetch(:foundations, []).join(', ')
                  "- #{opt[:id] || opt[:action]}: #{opt[:description]} (foundations: #{foundations_str})"
                end.join("\n")
                <<~PROMPT
                  Resolve this moral dilemma using the #{framework} ethical framework.

                  DILEMMA: #{dilemma_description}

                  OPTIONS:
                  #{option_lines}

                  Apply #{framework} reasoning to select the best option.

                  Format EXACTLY as:
                  CHOSEN: <option label>
                  CONFIDENCE: <0.0-1.0>
                  REASONING: <1-2 paragraph justification using the specified framework>
                PROMPT
              end
              private_class_method :build_resolve_dilemma_prompt

              def parse_resolve_dilemma_response(response)
                return nil unless response&.content

                text             = response.content
                chosen_match     = text.match(/CHOSEN:\s*(.+)/i)
                confidence_match = text.match(/CONFIDENCE:\s*([\d.]+)/i)
                reasoning_match  = text.match(/REASONING:\s*(.+)/im)
                return nil unless chosen_match && confidence_match && reasoning_match

                {
                  chosen_option: chosen_match.captures.first.strip,
                  confidence:    confidence_match.captures.first.strip.to_f.clamp(0.0, 1.0),
                  reasoning:     reasoning_match.captures.first.strip
                }
              end
              private_class_method :parse_resolve_dilemma_response
            end
          end
        end
      end
    end
  end
end
