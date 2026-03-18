# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Mentalizing
          module Helpers
            class BeliefAttribution
              attr_reader :id, :agent_id, :subject, :content, :depth, :about_agent_id, :created_at
              attr_accessor :confidence

              def initialize(agent_id:, subject:, content:, confidence:, depth: 0, about_agent_id: nil)
                @id             = SecureRandom.uuid
                @agent_id       = agent_id
                @subject        = subject
                @content        = content
                @confidence     = confidence.clamp(0.0, 1.0)
                @depth          = depth
                @about_agent_id = about_agent_id
                @created_at     = Time.now.utc
              end

              def decay
                @confidence = [@confidence - Constants::BELIEF_DECAY, Constants::BELIEF_FLOOR].max
              end

              def reinforce(amount: Constants::CONFIDENCE_ALPHA)
                @confidence = [@confidence + amount, 1.0].min
              end

              def label
                Constants::CONFIDENCE_LABELS.each do |range, lbl|
                  return lbl if range.cover?(@confidence)
                end
                :unknown
              end

              def to_h
                {
                  id:             @id,
                  agent_id:       @agent_id,
                  subject:        @subject,
                  content:        @content,
                  confidence:     @confidence,
                  depth:          @depth,
                  about_agent_id: @about_agent_id,
                  label:          label,
                  created_at:     @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
