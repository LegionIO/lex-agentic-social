# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Mentalizing
          module Runners
            module Mentalizing
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def attribute_belief(agent_id:, subject:, content:, confidence: nil, depth: 0, about_agent_id: nil, **)
                depth = [depth.to_i, Helpers::Constants::MAX_RECURSION_DEPTH].min
                conf  = confidence || Helpers::Constants::DEFAULT_CONFIDENCE
                belief = mental_model.attribute_belief(
                  agent_id:       agent_id,
                  subject:        subject,
                  content:        content,
                  confidence:     conf.to_f,
                  depth:          depth,
                  about_agent_id: about_agent_id
                )
                log.debug "[mentalizing] attribute agent=#{agent_id} subject=#{subject} depth=#{depth} conf=#{belief.confidence.round(2)}"
                { attributed: true, belief: belief.to_h }
              end

              def project_belief(subject:, own_belief:, other_agent_id:, **)
                belief = mental_model.project_self(subject: subject, own_belief: own_belief.to_f, other_agent_id: other_agent_id)
                log.debug "[mentalizing] project subject=#{subject} other=#{other_agent_id} discounted_conf=#{belief.confidence.round(2)}"
                { projected: true, belief: belief.to_h }
              end

              def check_alignment(agent_a:, agent_b:, subject:, **)
                score = mental_model.alignment(agent_a: agent_a, agent_b: agent_b, subject: subject)
                log.debug "[mentalizing] alignment agent_a=#{agent_a} agent_b=#{agent_b} subject=#{subject} score=#{score.round(2)}"
                { agent_a: agent_a, agent_b: agent_b, subject: subject, alignment: score.round(4) }
              end

              def detect_false_belief(agent_id:, subject:, reality:, **)
                result = mental_model.detect_false_belief(agent_id: agent_id, subject: subject, reality: reality)
                log.info "[mentalizing] false_belief_check agent=#{agent_id} subject=#{subject} false=#{result[:false_belief]}"
                result
              end

              def beliefs_for_agent(agent_id:, **)
                beliefs = mental_model.beliefs_for(agent_id: agent_id)
                log.debug "[mentalizing] beliefs_for agent=#{agent_id} count=#{beliefs.size}"
                { agent_id: agent_id, beliefs: beliefs.map(&:to_h), count: beliefs.size }
              end

              def beliefs_about_agent(about_agent_id:, **)
                beliefs = mental_model.beliefs_about(about_agent_id: about_agent_id)
                log.debug "[mentalizing] beliefs_about about=#{about_agent_id} count=#{beliefs.size}"
                { about_agent_id: about_agent_id, beliefs: beliefs.map(&:to_h), count: beliefs.size }
              end

              def recursive_belief_lookup(agent_id:, about_agent_id:, subject:, **)
                belief = mental_model.recursive_belief(agent_id: agent_id, about_agent_id: about_agent_id, subject: subject)
                if belief
                  log.debug "[mentalizing] recursive agent=#{agent_id} about=#{about_agent_id} subject=#{subject} found=true"
                  { found: true, belief: belief.to_h }
                else
                  log.debug "[mentalizing] recursive agent=#{agent_id} about=#{about_agent_id} subject=#{subject} found=false"
                  { found: false, agent_id: agent_id, about_agent_id: about_agent_id, subject: subject }
                end
              end

              def update_mentalizing(**)
                mental_model.decay_all
                log.debug "[mentalizing] decay cycle agents=#{mental_model.agent_count} beliefs=#{mental_model.belief_count}"
                { decayed: true, agents: mental_model.agent_count, beliefs: mental_model.belief_count }
              end

              def mentalizing_stats(**)
                {
                  agents:  mental_model.agent_count,
                  beliefs: mental_model.belief_count
                }
              end

              private

              def mental_model
                @mental_model ||= Helpers::MentalModel.new
              end
            end
          end
        end
      end
    end
  end
end
