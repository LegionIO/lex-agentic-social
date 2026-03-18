# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Symbiosis
          module Runners
            module CognitiveSymbiosis
              extend self

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def create_bond(subsystem_a:, subsystem_b:, relationship_type:, strength: nil, benefit_ratio: nil, engine: nil, **)
                eng = engine || default_engine
                result = eng.create_bond(
                  subsystem_a:       subsystem_a,
                  subsystem_b:       subsystem_b,
                  relationship_type: relationship_type.to_sym,
                  strength:          strength,
                  benefit_ratio:     benefit_ratio
                )
                msg = if result[:created]
                        "[symbiosis] bond created: #{subsystem_a}<->#{subsystem_b} type=#{relationship_type}"
                      else
                        "[symbiosis] bond skipped: #{result[:reason]}"
                      end
                Legion::Logging.debug msg if defined?(Legion::Logging)
                { success: result[:created], **result }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def activate(subsystem_a:, subsystem_b:, amount: 0.05, engine: nil, **)
                eng = engine || default_engine
                result = eng.activate_interaction(
                  subsystem_a: subsystem_a,
                  subsystem_b: subsystem_b,
                  amount:      amount.clamp(0.0, 1.0)
                )
                found = result.fetch(:found, false)
                Legion::Logging.debug "[symbiosis] activate #{subsystem_a}<->#{subsystem_b} found=#{found}" if defined?(Legion::Logging)
                { success: found, **result }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def health_status(engine: nil, **)
                eng = engine || default_engine
                health = eng.measure_ecosystem_health
                Legion::Logging.debug "[symbiosis] health score=#{health[:score]} label=#{health[:label]}" if defined?(Legion::Logging)
                { success: true, **health }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def list_bonds(subsystem_id: nil, relationship_type: nil, engine: nil, **)
                eng = engine || default_engine
                bonds = if subsystem_id
                          eng.ecosystem.symbiotic_web(subsystem_id).map(&:to_h)
                        else
                          eng.ecosystem.all_bonds.map(&:to_h)
                        end

                bonds = bonds.select { |b| b[:relationship_type] == relationship_type.to_sym } if relationship_type
                Legion::Logging.debug "[symbiosis] list_bonds count=#{bonds.size}" if defined?(Legion::Logging)
                { success: true, bonds: bonds, count: bonds.size }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def detect_parasites(strength_threshold: 0.0, engine: nil, **)
                eng = engine || default_engine
                parasites = eng.detect_parasites(strength_threshold: strength_threshold.clamp(0.0, 1.0))
                Legion::Logging.debug "[symbiosis] detect_parasites count=#{parasites.size}" if defined?(Legion::Logging)
                { success: true, parasites: parasites, count: parasites.size }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def ecosystem_report(engine: nil, **)
                eng = engine || default_engine
                report = eng.ecosystem_report
                Legion::Logging.debug "[symbiosis] ecosystem_report health=#{report.dig(:health, :label)}" if defined?(Legion::Logging)
                { success: true, **report }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              private

              def default_engine
                @default_engine ||= Helpers::SymbiosisEngine.new
              end
            end
          end
        end
      end
    end
  end
end
