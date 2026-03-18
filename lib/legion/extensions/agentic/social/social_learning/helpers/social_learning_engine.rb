# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module SocialLearning
          module Helpers
            class SocialLearningEngine
              include Constants

              def initialize
                @models     = {}  # id -> ModelAgent
                @behaviors  = {}  # id -> ObservedBehavior
              end

              def register_model(agent_id:, domain:, prestige: Constants::DEFAULT_PRESTIGE)
                prune_models if @models.size >= Constants::MAX_MODELS

                model = ModelAgent.new(agent_id: agent_id, domain: domain, prestige: prestige)
                @models[model.id] = model
                model
              end

              def observe_behavior(model_id:, action:, domain:, outcome:, context: {})
                model = @models.fetch(model_id, nil)
                return nil unless model
                return nil if model.prestige < Constants::ATTENTION_THRESHOLD

                prune_behaviors if @behaviors.size >= Constants::MAX_BEHAVIORS

                behavior = ObservedBehavior.new(
                  model_agent_id: model_id,
                  action:         action,
                  domain:         domain,
                  outcome:        outcome,
                  context:        context
                )

                model.observe!(behavior: behavior, outcome: outcome)
                model.observed_behaviors << behavior
                @behaviors[behavior.id] = behavior
                behavior
              end

              def retained_behaviors(domain: nil)
                behaviors = @behaviors.values.select(&:retained?)
                return behaviors unless domain

                behaviors.select { |beh| beh.domain == domain }
              end

              def reproducible_behaviors(domain: nil)
                behaviors = retained_behaviors(domain: domain)
                behaviors.select { |beh| beh.retention >= Constants::REPRODUCTION_CONFIDENCE }
              end

              def reproduce_behavior(behavior_id:)
                behavior = @behaviors.fetch(behavior_id, nil)
                return nil unless behavior
                return nil unless behavior.retained?

                behavior.reproduced = true
                behavior
              end

              def reinforce_reproduction(behavior_id:, outcome:)
                behavior = @behaviors.fetch(behavior_id, nil)
                return nil unless behavior

                model = @models.fetch(behavior.model_agent_id, nil)
                return nil unless model

                case outcome
                when :positive
                  model.prestige = (model.prestige + Constants::REINFORCEMENT_BOOST).clamp(
                    Constants::PRESTIGE_FLOOR,
                    Constants::PRESTIGE_CEILING
                  )
                when :negative
                  model.prestige = (model.prestige - Constants::PUNISHMENT_PENALTY).clamp(
                    Constants::PRESTIGE_FLOOR,
                    Constants::PRESTIGE_CEILING
                  )
                end

                { behavior: behavior.to_h, model_prestige: model.prestige.round(4) }
              end

              def best_models(limit: 5)
                @models.values
                       .sort_by { |mod| -mod.prestige }
                       .first(limit)
              end

              def by_domain(domain:)
                @models.values.select { |mod| mod.domain == domain }
              end

              def decay_all
                @behaviors.each_value(&:decay_retention!)
              end

              def prune_forgotten
                @behaviors.delete_if { |_id, beh| beh.retention < 0.05 }
              end

              def to_h
                {
                  model_count:        @models.size,
                  behavior_count:     @behaviors.size,
                  retained_count:     retained_behaviors.size,
                  reproducible_count: reproducible_behaviors.size
                }
              end

              private

              def prune_models
                oldest = @models.values.min_by(&:created_at)
                @models.delete(oldest.id) if oldest
              end

              def prune_behaviors
                oldest = @behaviors.values.min_by(&:created_at)
                @behaviors.delete(oldest.id) if oldest
              end
            end
          end
        end
      end
    end
  end
end
