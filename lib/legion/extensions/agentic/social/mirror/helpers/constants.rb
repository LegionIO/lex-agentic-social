# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Mirror
          module Helpers
            module Constants
              MAX_EVENTS              = 500
              MAX_SIMULATIONS         = 300
              DEFAULT_RESONANCE       = 0.5
              RESONANCE_BOOST         = 0.1
              RESONANCE_DECAY         = 0.03
              SIMULATION_CONFIDENCE_DEFAULT = 0.5

              ACTION_TYPES = %i[
                movement
                communication
                decision
                emotional_expression
                creative_act
                analytical_task
                social_interaction
                unknown
              ].freeze

              RESONANCE_LABELS = {
                (0.0..0.2) => :minimal,
                (0.2..0.4) => :low,
                (0.4..0.6) => :moderate,
                (0.6..0.8) => :high,
                (0.8..1.0) => :deep
              }.freeze

              CONFIDENCE_LABELS = {
                (0.0..0.2) => :uncertain,
                (0.2..0.4) => :tentative,
                (0.4..0.6) => :plausible,
                (0.6..0.8) => :confident,
                (0.8..1.0) => :certain
              }.freeze

              EMPATHY_LABELS = {
                (0.0..0.2) => :detached,
                (0.2..0.4) => :aware,
                (0.4..0.6) => :attuned,
                (0.6..0.8) => :resonant,
                (0.8..1.0) => :immersed
              }.freeze

              def self.label_for(labels_hash, value)
                clamped = value.clamp(0.0, 1.0)
                labels_hash.each do |range, label|
                  return label if range.cover?(clamped)
                end
                labels_hash.values.last
              end
            end
          end
        end
      end
    end
  end
end
