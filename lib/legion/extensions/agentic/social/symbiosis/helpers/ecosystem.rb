# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Symbiosis
          module Helpers
            class Ecosystem
              def initialize
                @bonds = {}
              end

              def register_bond(bond)
                raise ArgumentError, 'bond must be a SymbioticBond' unless bond.is_a?(SymbioticBond)
                raise ArgumentError, "MAX_BONDS (#{Constants::MAX_BONDS}) exceeded" if @bonds.size >= Constants::MAX_BONDS

                @bonds[bond.bond_id] = bond
                bond
              end

              def activate_bond(bond_id, amount: 0.05)
                bond = @bonds[bond_id]
                return { found: false, bond_id: bond_id } unless bond

                bond.activate!(amount: amount)
                { found: true, bond_id: bond_id, strength: bond.strength, activation_count: bond.activation_count }
              end

              def measure_health
                return 0.0 if @bonds.empty?

                active = @bonds.values.reject(&:dormant?)
                return 0.0 if active.empty?

                mutualistic = active.count { |b| b.relationship_type == :mutualistic }
                parasitic   = active.count { |b| b.relationship_type == :parasitic }
                total_active = active.size

                mutualistic_ratio = mutualistic.to_f / total_active
                parasite_penalty  = parasitic.to_f / total_active * 0.5

                (mutualistic_ratio - parasite_penalty).clamp(0.0, 1.0).round(10)
              end

              def health_label
                score = measure_health
                Constants::ECOSYSTEM_HEALTH_LABELS.each do |range, label|
                  return label if range.cover?(score)
                end
                :critical
              end

              def most_beneficial
                @bonds.values
                      .select { |b| b.relationship_type == :mutualistic && !b.dormant? }
                      .max_by { |b| b.benefit_ratio * b.strength }
              end

              def most_parasitic
                @bonds.values
                      .select { |b| b.relationship_type == :parasitic && !b.dormant? }
                      .min_by { |b| b.benefit_ratio * b.strength }
              end

              def decay_all!
                decayed = 0
                @bonds.each_value do |bond|
                  bond.decay!
                  decayed += 1
                end
                decayed
              end

              def network_density
                return 0.0 if @bonds.empty?

                active = @bonds.values.reject(&:dormant?)
                return 0.0 if active.empty?

                avg_strength = active.sum(&:strength) / active.size.to_f
                avg_strength.clamp(0.0, 1.0).round(10)
              end

              def symbiotic_web(subsystem_id)
                @bonds.values.select { |b| b.involves?(subsystem_id) }
              end

              def find_bond(subsystem_a, subsystem_b)
                @bonds.values.find do |b|
                  (b.subsystem_a == subsystem_a && b.subsystem_b == subsystem_b) ||
                    (b.subsystem_a == subsystem_b && b.subsystem_b == subsystem_a)
                end
              end

              def all_bonds
                @bonds.values
              end

              def bond_count
                @bonds.size
              end

              def active_bonds
                @bonds.values.reject(&:dormant?)
              end
            end
          end
        end
      end
    end
  end
end
