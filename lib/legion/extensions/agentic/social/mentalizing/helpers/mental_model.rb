# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Mentalizing
          module Helpers
            class MentalModel
              def initialize
                @models = {}
              end

              def attribute_belief(agent_id:, subject:, content:, confidence:, depth: 0, about_agent_id: nil)
                ensure_agent_capacity(agent_id)
                capped_depth = [depth.to_i, Constants::MAX_RECURSION_DEPTH].min
                belief = BeliefAttribution.new(
                  agent_id:       agent_id,
                  subject:        subject,
                  content:        content,
                  confidence:     confidence,
                  depth:          capped_depth,
                  about_agent_id: about_agent_id
                )
                @models[agent_id] ||= []
                @models[agent_id] << belief
                prune_agent_beliefs(agent_id)
                belief
              end

              def beliefs_for(agent_id:)
                @models[agent_id] || []
              end

              def beliefs_about(about_agent_id:)
                @models.values.flatten.select { |b| b.about_agent_id == about_agent_id }
              end

              def recursive_belief(agent_id:, about_agent_id:, subject:)
                beliefs = beliefs_for(agent_id: agent_id)
                beliefs.select { |b| b.about_agent_id == about_agent_id && b.subject == subject }
                       .max_by(&:confidence)
              end

              def project_self(subject:, own_belief:, other_agent_id:)
                discounted = (own_belief * Constants::PROJECTION_DISCOUNT).clamp(0.0, 1.0)
                attribute_belief(
                  agent_id:       :self,
                  subject:        subject,
                  content:        "projected: #{other_agent_id} thinks I believe this",
                  confidence:     discounted,
                  depth:          1,
                  about_agent_id: other_agent_id
                )
              end

              def alignment(agent_a:, agent_b:, subject:)
                beliefs_a = beliefs_on_subject(agent_a, subject)
                beliefs_b = beliefs_on_subject(agent_b, subject)
                return 0.0 if beliefs_a.empty? || beliefs_b.empty?

                conf_a = beliefs_a.map(&:confidence).sum / beliefs_a.size
                conf_b = beliefs_b.map(&:confidence).sum / beliefs_b.size
                1.0 - (conf_a - conf_b).abs
              end

              def detect_false_belief(agent_id:, subject:, reality:)
                relevant = beliefs_for(agent_id: agent_id).select { |b| b.subject == subject }
                return { false_belief: false, reason: :no_beliefs } if relevant.empty?

                strongest = relevant.max_by(&:confidence)
                false_belief = strongest.content != reality
                {
                  false_belief: false_belief,
                  agent_id:     agent_id,
                  subject:      subject,
                  held_belief:  strongest.content,
                  reality:      reality,
                  confidence:   strongest.confidence
                }
              end

              def decay_all
                @models.each_value { |beliefs| beliefs.each(&:decay) }
                prune_expired
              end

              def remove_agent(agent_id:)
                @models.delete(agent_id)
              end

              def agent_count
                @models.size
              end

              def belief_count
                @models.values.sum(&:size)
              end

              def to_h
                @models.transform_values { |beliefs| beliefs.map(&:to_h) }
              end

              private

              def beliefs_on_subject(agent_id, subject)
                beliefs_for(agent_id: agent_id).select { |b| b.subject == subject }
              end

              def ensure_agent_capacity(agent_id)
                return if @models.size < Constants::MAX_AGENTS
                return if @models.key?(agent_id)

                oldest_key = @models.keys.first
                @models.delete(oldest_key)
              end

              def prune_agent_beliefs(agent_id)
                list = @models[agent_id]
                return unless list && list.size > Constants::MAX_BELIEFS_PER_AGENT

                @models[agent_id] = list.sort_by(&:confidence).last(Constants::MAX_BELIEFS_PER_AGENT)
              end

              def prune_expired
                @models.each_value do |beliefs|
                  beliefs.reject! { |b| b.confidence <= Constants::BELIEF_FLOOR }
                end
                @models.reject! { |_, v| v.empty? }
              end
            end
          end
        end
      end
    end
  end
end
