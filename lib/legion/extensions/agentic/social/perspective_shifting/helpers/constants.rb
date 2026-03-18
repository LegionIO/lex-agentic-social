# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module PerspectiveShifting
          module Helpers
            module Constants
              MAX_PERSPECTIVES             = 50
              MAX_SITUATIONS               = 200
              MAX_VIEWS_PER_SITUATION      = 20
              DEFAULT_EMPATHY              = 0.5
              MIN_PERSPECTIVES_FOR_SYNTHESIS = 2

              PERSPECTIVE_TYPES = %i[
                stakeholder emotional temporal cultural ethical pragmatic creative adversarial
              ].freeze

              PRIORITY_TYPES = %i[
                safety efficiency fairness innovation stability growth autonomy compliance
              ].freeze

              EMPATHY_LABELS = {
                (0.8..)     => :deeply_empathic,
                (0.6...0.8) => :empathic,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :limited,
                (..0.2)     => :detached
              }.freeze

              COVERAGE_LABELS = {
                (0.8..)     => :comprehensive,
                (0.6...0.8) => :thorough,
                (0.4...0.6) => :partial,
                (0.2...0.4) => :narrow,
                (..0.2)     => :blind
              }.freeze

              AGREEMENT_LABELS = {
                (0.8..)     => :consensus,
                (0.6...0.8) => :agreement,
                (0.4...0.6) => :mixed,
                (0.2...0.4) => :disagreement,
                (..0.2)     => :conflict
              }.freeze

              module_function

              def empathy_label(value)
                EMPATHY_LABELS.find { |range, _| range.include?(value) }&.last || :detached
              end

              def coverage_label(value)
                COVERAGE_LABELS.find { |range, _| range.include?(value) }&.last || :blind
              end

              def agreement_label(value)
                AGREEMENT_LABELS.find { |range, _| range.include?(value) }&.last || :conflict
              end
            end
          end
        end
      end
    end
  end
end
