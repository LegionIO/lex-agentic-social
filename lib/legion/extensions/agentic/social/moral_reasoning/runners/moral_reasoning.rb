# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module MoralReasoning
          module Runners
            module MoralReasoning
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def evaluate_moral_action(action:, affected_foundations:, domain: :general, description: nil, **)
                log.debug "[moral_reasoning] evaluate_action: action=#{action} domain=#{domain}"

                if Helpers::LlmEnhancer.available?
                  current_foundations = engine.foundation_profile.transform_values { |f| f[:weight] }
                  llm_result = Helpers::LlmEnhancer.evaluate_action(
                    action:      action,
                    description: description.to_s,
                    foundations: current_foundations
                  )
                  if llm_result
                    log.debug "[moral_reasoning] using LLM evaluation for action=#{action}"
                    result = engine.evaluate_action(
                      action:               action,
                      affected_foundations: affected_foundations,
                      domain:               domain
                    )
                    return { success: true, source: :llm, reasoning: llm_result[:reasoning],
                             foundation_impacts: llm_result[:foundation_impacts] }.merge(result)
                  end
                end

                result = engine.evaluate_action(action: action, affected_foundations: affected_foundations, domain: domain)
                { success: true, source: :mechanical }.merge(result)
              end

              def pose_moral_dilemma(description:, options:, domain: :general, severity: 0.5, **)
                log.info "[moral_reasoning] pose_dilemma: domain=#{domain} severity=#{severity}"
                engine.pose_dilemma(description: description, options: options, domain: domain, severity: severity)
              end

              def resolve_moral_dilemma(dilemma_id:, option_id:, reasoning:, framework:, **)
                log.info "[moral_reasoning] resolve_dilemma: id=#{dilemma_id} framework=#{framework}"

                if Helpers::LlmEnhancer.available?
                  dilemma = engine.dilemmas[dilemma_id]
                  if dilemma && !dilemma.resolved?
                    llm_result = Helpers::LlmEnhancer.resolve_dilemma(
                      dilemma_description: dilemma.description,
                      options:             dilemma.options,
                      framework:           framework
                    )
                    if llm_result
                      log.debug "[moral_reasoning] using LLM resolution for dilemma=#{dilemma_id}"
                      result = engine.resolve_dilemma(
                        dilemma_id: dilemma_id,
                        option_id:  option_id,
                        reasoning:  llm_result[:reasoning],
                        framework:  framework
                      )
                      return result.merge(source: :llm, llm_chosen: llm_result[:chosen_option],
                                          llm_confidence: llm_result[:confidence])
                    end
                  end
                end

                engine.resolve_dilemma(dilemma_id: dilemma_id, option_id: option_id,
                                       reasoning: reasoning, framework: framework)
              end

              def apply_ethical_framework(dilemma_id:, framework:, **)
                log.debug "[moral_reasoning] apply_framework: id=#{dilemma_id} framework=#{framework}"
                engine.apply_framework(dilemma_id: dilemma_id, framework: framework)
              end

              def add_moral_principle(name:, description:, foundation:, weight: Helpers::Constants::DEFAULT_WEIGHT, **)
                log.info "[moral_reasoning] add_principle: name=#{name} foundation=#{foundation}"
                engine.add_principle(name: name, description: description, foundation: foundation, weight: weight)
              end

              def check_moral_development(**)
                log.debug '[moral_reasoning] check_moral_development'
                result = engine.moral_development
                { success: true }.merge(result)
              end

              def moral_foundation_profile(**)
                log.debug '[moral_reasoning] foundation_profile'
                { success: true, foundations: engine.foundation_profile }
              end

              def moral_stage_info(**)
                log.debug '[moral_reasoning] stage_info'
                { success: true }.merge(engine.stage_info)
              end

              def update_moral_reasoning(**)
                log.debug '[moral_reasoning] decay_all'
                engine.decay_all
                { success: true, foundations: engine.foundation_profile }
              end

              def moral_reasoning_stats(**)
                log.debug '[moral_reasoning] stats'
                { success: true }.merge(engine.to_h)
              end

              private

              def engine
                @engine ||= Helpers::MoralEngine.new
              end
            end
          end
        end
      end
    end
  end
end
