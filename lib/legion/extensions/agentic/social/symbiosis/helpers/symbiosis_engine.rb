# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Symbiosis
          module Helpers
            class SymbiosisEngine
              def initialize
                @ecosystem = Ecosystem.new
              end

              def create_bond(subsystem_a:, subsystem_b:, relationship_type:, strength: nil, benefit_ratio: nil)
                existing = @ecosystem.find_bond(subsystem_a, subsystem_b)
                return { created: false, reason: :already_exists, bond: existing.to_h } if existing

                bond = SymbioticBond.new(
                  subsystem_a:       subsystem_a,
                  subsystem_b:       subsystem_b,
                  relationship_type: relationship_type,
                  strength:          strength,
                  benefit_ratio:     benefit_ratio
                )
                @ecosystem.register_bond(bond)
                { created: true, bond: bond.to_h }
              rescue ArgumentError => e
                { created: false, reason: :invalid_arguments, error: e.message }
              end

              def activate_interaction(subsystem_a:, subsystem_b:, amount: 0.05)
                bond = @ecosystem.find_bond(subsystem_a, subsystem_b)
                return { found: false, subsystem_a: subsystem_a, subsystem_b: subsystem_b } unless bond

                result = @ecosystem.activate_bond(bond.bond_id, amount: amount)
                result.merge(
                  relationship_type: bond.relationship_type,
                  benefit_ratio:     bond.benefit_ratio
                )
              end

              def measure_ecosystem_health
                score = @ecosystem.measure_health
                {
                  score:           score,
                  label:           @ecosystem.health_label,
                  bond_count:      @ecosystem.bond_count,
                  active_bonds:    @ecosystem.active_bonds.size,
                  network_density: @ecosystem.network_density
                }
              end

              def find_partners(subsystem_id, min_benefit_ratio: 0.0)
                @ecosystem.symbiotic_web(subsystem_id)
                          .reject(&:dormant?)
                          .select { |b| b.benefit_ratio >= min_benefit_ratio }
                          .sort_by { |b| -b.strength }
                          .map do |b|
                            b.to_h.merge(partner: b.partner_of(subsystem_id))
                          end
              end

              def detect_parasites(strength_threshold: 0.0)
                @ecosystem.all_bonds
                          .select { |b| b.relationship_type == :parasitic }
                          .reject(&:dormant?)
                          .select { |b| b.strength >= strength_threshold }
                          .sort_by(&:benefit_ratio)
                          .map(&:to_h)
              end

              def ecosystem_report
                bonds_by_type = Constants::RELATIONSHIP_TYPES.to_h do |type|
                  count = @ecosystem.all_bonds.count { |b| b.relationship_type == type && !b.dormant? }
                  [type, count]
                end

                health    = measure_ecosystem_health
                strongest = @ecosystem.most_beneficial&.to_h
                weakest   = @ecosystem.most_parasitic&.to_h

                {
                  health:          health,
                  bonds_by_type:   bonds_by_type,
                  most_beneficial: strongest,
                  most_parasitic:  weakest,
                  total_bonds:     @ecosystem.bond_count,
                  dormant_bonds:   @ecosystem.all_bonds.count(&:dormant?)
                }
              end

              def decay_all
                decayed = @ecosystem.decay_all!
                { decayed: decayed, health_after: measure_ecosystem_health }
              end

              attr_reader :ecosystem
            end
          end
        end
      end
    end
  end
end
