# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Symbiosis
          module Helpers
            module Constants
              RELATIONSHIP_TYPES = %i[mutualistic parasitic commensal].freeze

              INTERACTION_STRENGTHS = {
                0.0..0.2 => :dormant,
                0.2..0.4 => :weak,
                0.4..0.6 => :moderate,
                0.6..0.8 => :strong,
                0.8..1.0 => :dominant
              }.freeze

              MAX_BONDS       = 200
              BOND_DECAY      = 0.02
              STRONG_THRESHOLD = 0.6
              DORMANT_THRESHOLD = 0.05
              MIN_STRENGTH    = 0.0
              MAX_STRENGTH    = 1.0
              DEFAULT_STRENGTH = 0.3

              # Mutualism: both gain, benefit_ratio > 0
              # Parasitism: one drains the other, benefit_ratio < 0
              # Commensalism: one benefits, other unaffected, benefit_ratio ~0 for host
              BENEFIT_RATIO_RANGES = {
                mutualistic: (0.1..1.0),
                parasitic:   (-1.0..-0.1),
                commensal:   (-0.05..0.05)
              }.freeze

              ECOSYSTEM_HEALTH_LABELS = {
                0.0..0.2 => :critical,
                0.2..0.4 => :stressed,
                0.4..0.6 => :balanced,
                0.6..0.8 => :thriving,
                0.8..1.0 => :flourishing
              }.freeze
            end
          end
        end
      end
    end
  end
end
