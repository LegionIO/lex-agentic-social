# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module SocialLearning
          module Runners
            module SocialLearning
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def register_model_agent(agent_id:, domain:, prestige: nil, **)
                init_prestige = prestige || Helpers::Constants::DEFAULT_PRESTIGE
                log.debug "[social_learning] register_model agent=#{agent_id} domain=#{domain} prestige=#{init_prestige}"
                model = engine.register_model(agent_id: agent_id, domain: domain, prestige: init_prestige)
                { success: true, model: model.to_h }
              end

              def observe_agent_behavior(model_id:, action:, domain:, outcome:, context: {}, **)
                log.debug "[social_learning] observe model=#{model_id} action=#{action} domain=#{domain} outcome=#{outcome}"
                behavior = engine.observe_behavior(
                  model_id: model_id,
                  action:   action,
                  domain:   domain,
                  outcome:  outcome,
                  context:  context
                )
                if behavior
                  { success: true, behavior: behavior.to_h }
                else
                  { success: false, reason: 'model not found or below attention threshold' }
                end
              end

              def retained_behaviors(domain: nil, **)
                log.debug "[social_learning] retained_behaviors domain=#{domain.inspect}"
                behaviors = engine.retained_behaviors(domain: domain)
                { success: true, behaviors: behaviors.map(&:to_h), count: behaviors.size }
              end

              def reproducible_behaviors(domain: nil, **)
                log.debug "[social_learning] reproducible_behaviors domain=#{domain.inspect}"
                behaviors = engine.reproducible_behaviors(domain: domain)
                { success: true, behaviors: behaviors.map(&:to_h), count: behaviors.size }
              end

              def reproduce_observed_behavior(behavior_id:, **)
                log.debug "[social_learning] reproduce behavior_id=#{behavior_id}"
                behavior = engine.reproduce_behavior(behavior_id: behavior_id)
                if behavior
                  { success: true, behavior: behavior.to_h }
                else
                  { success: false, reason: 'behavior not found or retention too low' }
                end
              end

              def reinforce_reproduction(behavior_id:, outcome:, **)
                log.debug "[social_learning] reinforce behavior_id=#{behavior_id} outcome=#{outcome}"
                result = engine.reinforce_reproduction(behavior_id: behavior_id, outcome: outcome)
                if result
                  { success: true }.merge(result)
                else
                  { success: false, reason: 'behavior or model not found' }
                end
              end

              def best_model_agents(limit: 5, **)
                lim = limit.to_i
                log.debug "[social_learning] best_model_agents limit=#{lim}"
                models = engine.best_models(limit: lim)
                { success: true, models: models.map(&:to_h), count: models.size }
              end

              def domain_models(domain:, **)
                log.debug "[social_learning] domain_models domain=#{domain}"
                models = engine.by_domain(domain: domain)
                { success: true, models: models.map(&:to_h), count: models.size }
              end

              def update_social_learning(**)
                log.debug '[social_learning] update_social_learning decay+prune cycle'
                engine.decay_all
                engine.prune_forgotten
                stats = engine.to_h
                { success: true }.merge(stats)
              end

              def social_learning_stats(**)
                log.debug '[social_learning] social_learning_stats'
                { success: true }.merge(engine.to_h)
              end

              private

              def engine
                @engine ||= Helpers::SocialLearningEngine.new
              end
            end
          end
        end
      end
    end
  end
end
