# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module Entrainment
          module Helpers
            class Pairing
              include Constants

              attr_reader :id, :agent_a, :agent_b, :domain, :synchrony,
                          :interaction_count, :created_at, :last_interaction_at

              def initialize(agent_a:, agent_b:, domain:)
                @id                 = SecureRandom.uuid
                @agent_a            = agent_a
                @agent_b            = agent_b
                @domain             = domain
                @synchrony          = DEFAULT_SYNC
                @interaction_count  = 0
                @created_at         = Time.now.utc
                @last_interaction_at = @created_at
              end

              def interact!(aligned:)
                @interaction_count  += 1
                @last_interaction_at = Time.now.utc

                @synchrony = if aligned
                               (@synchrony + COUPLING_RATE).clamp(SYNC_FLOOR, SYNC_CEILING)
                             else
                               (@synchrony - DECOUPLING_RATE).clamp(SYNC_FLOOR, SYNC_CEILING)
                             end
              end

              def drift!
                @synchrony = (@synchrony - NATURAL_DRIFT).clamp(SYNC_FLOOR, SYNC_CEILING)
              end

              def entrained?
                @synchrony >= ENTRAINED_THRESHOLD
              end

              def partially_entrained?
                @synchrony >= PARTIAL_THRESHOLD && @synchrony < ENTRAINED_THRESHOLD
              end

              def sync_label
                SYNC_LABELS.find { |range, _| range.cover?(@synchrony) }&.last || :unknown
              end

              def involves?(agent_id)
                [@agent_a, @agent_b].include?(agent_id)
              end

              def partner_of(agent_id)
                return @agent_b if @agent_a == agent_id
                return @agent_a if @agent_b == agent_id

                nil
              end

              def to_h
                {
                  id:                  @id,
                  agent_a:             @agent_a,
                  agent_b:             @agent_b,
                  domain:              @domain,
                  synchrony:           @synchrony,
                  sync_label:          sync_label,
                  entrained:           entrained?,
                  interaction_count:   @interaction_count,
                  created_at:          @created_at,
                  last_interaction_at: @last_interaction_at
                }
              end
            end
          end
        end
      end
    end
  end
end
