# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module SocialLearning
          module Helpers
            class ModelAgent
              include Constants

              attr_reader :id, :agent_id, :domain, :observation_count,
                          :success_count, :created_at, :last_observed_at,
                          :observed_behaviors
              attr_accessor :prestige

              def initialize(agent_id:, domain:, prestige: Constants::DEFAULT_PRESTIGE)
                @id                 = SecureRandom.uuid
                @agent_id           = agent_id
                @domain             = domain
                @prestige           = prestige.clamp(Constants::PRESTIGE_FLOOR, Constants::PRESTIGE_CEILING)
                @observed_behaviors = []
                @observation_count  = 0
                @success_count      = 0
                @created_at         = Time.now.utc
                @last_observed_at   = nil
              end

              def observe!(behavior:, outcome:)
                @observation_count += 1
                @last_observed_at = Time.now.utc

                if outcome == :positive
                  @success_count += 1
                  @prestige = (@prestige + Constants::PRESTIGE_LEARNING_RATE).clamp(
                    Constants::PRESTIGE_FLOOR,
                    Constants::PRESTIGE_CEILING
                  )
                elsif outcome == :negative
                  @prestige = (@prestige - Constants::PRESTIGE_LEARNING_RATE).clamp(
                    Constants::PRESTIGE_FLOOR,
                    Constants::PRESTIGE_CEILING
                  )
                end

                behavior
              end

              def prestige_label
                Constants::MODEL_LABELS.find { |range, _label| range.include?(@prestige) }&.last || :unknown
              end

              def success_rate
                return 0.0 if @observation_count.zero?

                (@success_count.to_f / @observation_count).round(4)
              end

              def to_h
                {
                  id:                @id,
                  agent_id:          @agent_id,
                  domain:            @domain,
                  prestige:          @prestige.round(4),
                  prestige_label:    prestige_label,
                  observation_count: @observation_count,
                  success_count:     @success_count,
                  success_rate:      success_rate,
                  behavior_count:    @observed_behaviors.size,
                  created_at:        @created_at,
                  last_observed_at:  @last_observed_at
                }
              end
            end
          end
        end
      end
    end
  end
end
