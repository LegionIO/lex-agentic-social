# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module MoralReasoning
          module Helpers
            class Dilemma
              include Constants

              attr_reader :id, :description, :domain, :severity, :options,
                          :chosen_option, :reasoning, :framework_used,
                          :created_at, :resolved_at

              def initialize(id:, description:, options:, domain: :general, severity: 0.5)
                @id           = id
                @description  = description
                @domain       = domain
                @severity     = severity.clamp(0.0, 1.0)
                @options      = options
                @chosen_option = nil
                @reasoning = nil
                @framework_used = nil
                @resolved     = false
                @created_at   = Time.now.utc
                @resolved_at  = nil
              end

              def severity_label
                SEVERITY_LABELS.find { |range, _| range.cover?(@severity) }&.last
              end

              def resolve(option_id:, reasoning:, framework:)
                @chosen_option  = option_id
                @reasoning      = reasoning
                @framework_used = framework
                @resolved       = true
                @resolved_at    = Time.now.utc
              end

              def resolved?
                @resolved
              end

              def to_h
                {
                  id:             @id,
                  description:    @description,
                  domain:         @domain,
                  severity:       @severity,
                  severity_label: severity_label,
                  options:        @options,
                  chosen_option:  @chosen_option,
                  reasoning:      @reasoning,
                  framework_used: @framework_used,
                  resolved:       @resolved,
                  created_at:     @created_at,
                  resolved_at:    @resolved_at
                }
              end
            end
          end
        end
      end
    end
  end
end
