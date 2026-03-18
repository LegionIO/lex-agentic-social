# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module MirrorSystem
          module Helpers
            class MirrorSystem
              include Constants

              attr_reader :observations, :repertoire, :fidelity_scores, :imitation_history

              def initialize
                @observations     = {}
                @repertoire       = {}
                @fidelity_scores  = {}
                @imitation_history = []
              end

              def observe(agent_id:, action:, domain:, context: nil, outcome: nil)
                key = observation_key(agent_id, action, domain)
                if @observations.key?(key)
                  @observations[key].observe_again
                  @observations[key]
                else
                  ensure_observation_capacity
                  obs = ObservedBehavior.new(
                    agent_id: agent_id,
                    action:   action,
                    domain:   domain,
                    context:  context,
                    outcome:  outcome
                  )
                  obs.boost_familiarity if repertoire_includes?(action, domain)
                  @observations[key] = obs
                end
              end

              def imitate(action:, domain:, source_agent: nil)
                candidates = if source_agent
                               observations_for_agent(source_agent).select { |o| o.action == action && o.domain == domain }
                             else
                               @observations.values.select { |o| o.action == action && o.domain == domain }
                             end
                return nil if candidates.empty?

                best = candidates.max_by(&:resonance)
                fidelity = fidelity_for(action, domain)
                add_to_repertoire(action, domain, fidelity)
                record_imitation(action, domain, source_agent, fidelity)
                { observation: best, fidelity: fidelity }
              end

              def add_to_repertoire(action, domain, fidelity = DEFAULT_FIDELITY)
                key = repertoire_key(action, domain)
                if @repertoire.key?(key)
                  old = @repertoire[key][:fidelity]
                  @repertoire[key][:fidelity] = ema(old, fidelity, MIRROR_ALPHA)
                  @repertoire[key][:practice_count] += 1
                else
                  trim_repertoire if @repertoire.size >= MAX_REPERTOIRE
                  @repertoire[key] = { action: action, domain: domain, fidelity: fidelity, practice_count: 1 }
                end
              end

              def update_fidelity(action:, domain:, success:)
                key = repertoire_key(action, domain)
                @fidelity_scores[key] ||= DEFAULT_FIDELITY
                delta = success ? FIDELITY_LEARNING_RATE : -FIDELITY_LEARNING_RATE
                @fidelity_scores[key] = (@fidelity_scores[key] + delta).clamp(0.0, 1.0)
              end

              def fidelity_for(action, domain)
                @fidelity_scores.fetch(repertoire_key(action, domain), DEFAULT_FIDELITY)
              end

              def observations_for_agent(agent_id)
                @observations.values.select { |o| o.agent_id == agent_id }
              end

              def observations_in_domain(domain)
                @observations.values.select { |o| o.domain == domain }
              end

              def strongest_mirrors(count = 5)
                @observations.values.sort_by { |o| -o.resonance }.first(count)
              end

              def repertoire_includes?(action, domain)
                @repertoire.key?(repertoire_key(action, domain))
              end

              def decay_all
                @observations.each_value(&:decay)
                @observations.reject! { |_, o| o.faded? }
              end

              def observation_count
                @observations.size
              end

              def repertoire_size
                @repertoire.size
              end

              def mirrored_agents
                @observations.values.map(&:agent_id).uniq
              end

              def to_h
                {
                  observations:    observation_count,
                  repertoire_size: repertoire_size,
                  mirrored_agents: mirrored_agents.size,
                  history_size:    @imitation_history.size
                }
              end

              private

              def observation_key(agent_id, action, domain)
                :"#{agent_id}:#{action}:#{domain}"
              end

              def repertoire_key(action, domain)
                :"#{action}:#{domain}"
              end

              def ema(old_val, new_val, alpha)
                old_val + (alpha * (new_val - old_val))
              end

              def ensure_observation_capacity
                return if @observations.size < MAX_OBSERVATIONS

                weakest = @observations.min_by { |_, o| o.resonance }
                @observations.delete(weakest.first) if weakest
              end

              def trim_repertoire
                weakest = @repertoire.min_by { |_, r| r[:fidelity] }
                @repertoire.delete(weakest.first) if weakest
              end

              def record_imitation(action, domain, source_agent, fidelity)
                @imitation_history << {
                  action:       action,
                  domain:       domain,
                  source_agent: source_agent,
                  fidelity:     fidelity,
                  at:           Time.now.utc
                }
                @imitation_history.shift while @imitation_history.size > MAX_OBSERVATIONS
              end
            end
          end
        end
      end
    end
  end
end
