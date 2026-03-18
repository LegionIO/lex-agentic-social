# frozen_string_literal: true

require 'securerandom'
require 'time'

module Legion
  module Extensions
    module Agentic
      module Social
        module Symbiosis
          module Helpers
            class SymbioticBond
              attr_reader :bond_id, :subsystem_a, :subsystem_b, :relationship_type,
                          :benefit_ratio, :activation_count, :created_at, :last_activated_at

              def initialize(subsystem_a:, subsystem_b:, relationship_type:, strength: nil, benefit_ratio: nil)
                validate_relationship_type!(relationship_type)

                @bond_id           = SecureRandom.uuid
                @subsystem_a       = subsystem_a
                @subsystem_b       = subsystem_b
                @relationship_type = relationship_type
                @strength          = (strength || Constants::DEFAULT_STRENGTH).clamp(
                  Constants::MIN_STRENGTH, Constants::MAX_STRENGTH
                )
                @benefit_ratio     = benefit_ratio || default_benefit_ratio(relationship_type)
                @activation_count  = 0
                @created_at        = Time.now.utc
                @last_activated_at = nil
              end

              def strength
                @strength.round(10)
              end

              def activate!(amount: 0.05)
                delta = amount.clamp(0.0, 1.0)
                @strength = (@strength + delta).clamp(Constants::MIN_STRENGTH, Constants::MAX_STRENGTH)
                @activation_count += 1
                @last_activated_at = Time.now.utc
                self
              end

              def decay!(rate: Constants::BOND_DECAY)
                @strength = (@strength - rate).clamp(Constants::MIN_STRENGTH, Constants::MAX_STRENGTH)
                self
              end

              def dormant?
                @strength <= Constants::DORMANT_THRESHOLD
              end

              def strong?
                @strength >= Constants::STRONG_THRESHOLD
              end

              def strength_label
                Constants::INTERACTION_STRENGTHS.each do |range, label|
                  return label if range.cover?(@strength)
                end
                :dormant
              end

              def involves?(subsystem_id)
                [@subsystem_a, @subsystem_b].include?(subsystem_id)
              end

              def partner_of(subsystem_id)
                return @subsystem_b if @subsystem_a == subsystem_id
                return @subsystem_a if @subsystem_b == subsystem_id

                nil
              end

              def to_h
                {
                  bond_id:           @bond_id,
                  subsystem_a:       @subsystem_a,
                  subsystem_b:       @subsystem_b,
                  relationship_type: @relationship_type,
                  strength:          strength,
                  strength_label:    strength_label,
                  benefit_ratio:     @benefit_ratio,
                  activation_count:  @activation_count,
                  dormant:           dormant?,
                  strong:            strong?,
                  created_at:        @created_at.iso8601,
                  last_activated_at: @last_activated_at&.iso8601
                }
              end

              private

              def validate_relationship_type!(type)
                return if Constants::RELATIONSHIP_TYPES.include?(type)

                raise ArgumentError, "unknown relationship_type: #{type.inspect}. " \
                                     "Must be one of #{Constants::RELATIONSHIP_TYPES.inspect}"
              end

              def default_benefit_ratio(type)
                range = Constants::BENEFIT_RATIO_RANGES.fetch(type)
                mid = (range.min + range.max) / 2.0
                mid.round(10)
              end
            end
          end
        end
      end
    end
  end
end
