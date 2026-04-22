# frozen_string_literal: true

# MirrorSystem::Helpers::ObservedBehavior models an ongoing observation of a
# specific agent's behavior pattern, keyed by (agent_id, action, domain). It
# tracks resonance (familiarity strength) that increases with repeated
# observations (observe_again) or explicit simulation boosts (boost_familiarity)
# and decays over time. Fidelity of imitation is tracked via observation_count.
#
# Distinct from SocialLearning::Helpers::ObservedBehavior, which is a one-shot
# snapshot of a behavior modeled from another agent, with retention (recall)
# mechanics and a reproduction flag. The SocialLearning variant focuses on
# whether the observer can reproduce what it saw; the MirrorSystem variant
# focuses on resonance-based familiarity and imitation fidelity over time.

module Legion
  module Extensions
    module Agentic
      module Social
        module MirrorSystem
          module Helpers
            class ObservedBehavior
              attr_reader :id, :agent_id, :action, :domain, :context, :outcome, :created_at
              attr_accessor :resonance, :observation_count

              def initialize(agent_id:, action:, domain:, context: nil, outcome: nil, resonance: nil)
                @id                = SecureRandom.uuid
                @agent_id          = agent_id
                @action            = action
                @domain            = domain
                @context           = context
                @outcome           = outcome
                @resonance         = (resonance || Constants::DEFAULT_RESONANCE).clamp(0.0, Constants::MAX_RESONANCE)
                @observation_count = 1
                @created_at        = Time.now.utc
              end

              def observe_again
                @observation_count += 1
                @resonance = [@resonance + Constants::REPETITION_BOOST, Constants::MAX_RESONANCE].min
              end

              def boost_familiarity
                @resonance = [@resonance + Constants::FAMILIARITY_BOOST, Constants::MAX_RESONANCE].min
              end

              def decay
                @resonance = [@resonance - Constants::RESONANCE_DECAY, Constants::RESONANCE_FLOOR].max
              end

              def faded?
                @resonance <= Constants::RESONANCE_FLOOR
              end

              def label
                Constants::RESONANCE_LABELS.each { |range, lbl| return lbl if range.cover?(@resonance) }
                :silent
              end

              def to_h
                {
                  id:                @id,
                  agent_id:          @agent_id,
                  action:            @action,
                  domain:            @domain,
                  context:           @context,
                  outcome:           @outcome,
                  resonance:         @resonance,
                  observation_count: @observation_count,
                  label:             label,
                  created_at:        @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
