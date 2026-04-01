# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Attachment
          module Runners
            module Attachment
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def update_attachment(tick_results: {}, human_observations: [], **)
                agents = collect_agent_ids(tick_results, human_observations)
                return { agents_updated: 0 } if agents.empty?

                agents.each do |agent_id|
                  model = attachment_store.get_or_create(agent_id)
                  signals = extract_signals(agent_id, tick_results, human_observations)
                  model.update_from_signals(signals)
                  model.update_stage!
                  model.derive_style!(extract_style_signals(agent_id, human_observations))
                end

                { agents_updated: agents.size, models: agents.map { |id| attachment_store.get(id)&.to_h } }
              end

              def reflect_on_bonds(_tick_results: {}, _bond_summary: {}, **)
                store = apollo_local_store
                return { success: false, error: :no_store } unless store

                partner_id    = resolve_partner_id
                model         = attachment_store.get(partner_id) if partner_id
                comm_patterns = read_communication_patterns(store, partner_id)
                arc_state     = read_relationship_arc(store, partner_id)
                health        = compute_relationship_health(model, comm_patterns, arc_state)

                {
                  bonds_reflected: attachment_store.all_models.size,
                  partner_bond:    if model
                                     {
                                       stage:                   model.bond_stage,
                                       strength:                model.attachment_strength,
                                       style:                   model.attachment_style,
                                       health:                  health,
                                       milestones_today:        arc_state[:milestones_today] || [],
                                       narrative:               build_narrative(model, health, arc_state),
                                       absence_exceeds_pattern: absence_exceeds_pattern?(partner_id)
                                     }
                                   end
                }
              rescue StandardError => e
                { success: false, error: e.message }
              end

              def attachment_stats(**)
                partner_id    = resolve_partner_id
                partner_model = attachment_store.get(partner_id) if partner_id
                {
                  bonds_tracked: attachment_store.all_models.size,
                  partner_bond:  partner_model&.to_h
                }
              end

              private

              def attachment_store
                @attachment_store ||= Helpers::AttachmentStore.new
              end

              def collect_agent_ids(tick_results, human_observations)
                ids = Set.new
                (tick_results.dig(:social_cognition, :reputation_updates) || []).each do |u|
                  ids << u[:agent_id].to_s if u[:agent_id]
                end
                human_observations.each { |o| ids << o[:agent_id].to_s if o[:agent_id] }
                ids.to_a
              end

              def extract_signals(agent_id, tick_results, human_observations)
                reputation = (tick_results.dig(:social_cognition, :reputation_updates) || [])
                             .find { |u| u[:agent_id].to_s == agent_id }
                prediction = tick_results.dig(:theory_of_mind, :prediction_accuracy) || {}
                obs = human_observations.select { |o| o[:agent_id].to_s == agent_id }

                direct_count = obs.count { |o| o[:direct_address] }
                channels = obs.filter_map { |o| o[:channel] }.uniq

                {
                  frequency_score:      obs.size.clamp(0, 10) / 10.0,
                  reciprocity_score:    (reputation&.dig(:composite) || 0.0).clamp(0.0, 1.0),
                  prediction_accuracy:  (prediction[agent_id] || 0.0).clamp(0.0, 1.0),
                  direct_address_ratio: obs.empty? ? 0.0 : (direct_count.to_f / obs.size).clamp(0.0, 1.0),
                  channel_consistency:  channels.size <= 1 ? 1.0 : (1.0 / channels.size).clamp(0.0, 1.0)
                }
              end

              def extract_style_signals(agent_id, human_observations)
                obs = human_observations.select { |o| o[:agent_id].to_s == agent_id }
                direct_count = obs.count { |o| o[:direct_address] }
                {
                  frequency_variance:    compute_frequency_variance(obs),
                  reciprocity_imbalance: compute_reciprocity_imbalance(obs),
                  frequency:             obs.size.clamp(0, 10) / 10.0,
                  direct_address_ratio:  obs.empty? ? 0.0 : direct_count.to_f / obs.size
                }
              end

              def compute_frequency_variance(observations)
                return 0.0 if observations.size < 3

                timestamps = observations.filter_map { |o| o[:observed_at] || o[:timestamp] }
                return 0.0 if timestamps.size < 3

                buckets = timestamps.group_by { |t| t.to_i / 3600 }
                counts  = buckets.values.map { |b| b.size.to_f }
                mean    = counts.sum / counts.size
                variance = counts.sum { |c| (c - mean)**2 } / counts.size
                [variance / [mean, 1.0].max, 1.0].min
              end

              def compute_reciprocity_imbalance(observations)
                return 0.0 if observations.empty?

                initiated = observations.count { |o| o[:initiated_by] == :agent || o[:direction] == :outgoing }
                received  = observations.size - initiated
                total     = observations.size.to_f
                return 0.0 if total.zero?

                ((initiated - received).abs / total).clamp(0.0, 1.0)
              end

              def resolve_partner_id
                if defined?(Legion::Gaia::BondRegistry)
                  bond = Legion::Gaia::BondRegistry.all_bonds.find { |b| b[:role] == :partner }
                  return bond&.dig(:identity)&.to_s
                end

                strongest = attachment_store.all_models.max_by(&:attachment_strength)
                strongest&.agent_id
              end

              def apollo_local_store
                return nil unless defined?(Legion::Apollo::Local) && Legion::Apollo::Local.started?

                Legion::Apollo::Local
              end

              def read_communication_patterns(store, partner_id)
                return {} unless partner_id

                result = store.query(text: 'communication_pattern',
                                     tags: ['bond', 'communication_pattern', partner_id])
                return {} unless result[:success] && result[:results]&.any?

                deserialize(result[:results].first[:content]) || {}
              rescue StandardError => _e
                {}
              end

              def read_relationship_arc(store, partner_id)
                return {} unless partner_id

                result = store.query(text: 'relationship_arc',
                                     tags: ['bond', 'relationship_arc', partner_id])
                return {} unless result[:success] && result[:results]&.any?

                deserialize(result[:results].first[:content]) || {}
              rescue StandardError => _e
                {}
              end

              def compute_relationship_health(model, comm_patterns, arc_state)
                return 0.0 unless model

                strength_component    = model.attachment_strength * 0.4
                reciprocity_component = (arc_state[:reciprocity_balance] || 0.5) * 0.3
                consistency_component = (comm_patterns[:consistency] || 0.5) * 0.3
                (strength_component + reciprocity_component + consistency_component).clamp(0.0, 1.0)
              end

              def build_narrative(model, health, arc_state)
                return nil unless model

                stage     = model.bond_stage
                style     = model.attachment_style
                chapter   = arc_state[:current_chapter]
                parts     = ["Bond is #{stage} (#{style} style)"]
                parts << "health: #{format('%.1f', health)}" if health
                parts << "chapter: #{chapter}" if chapter
                milestones = arc_state[:milestones_today]
                parts << "#{milestones.size} milestone(s) today" if milestones&.any?
                "#{parts.join(', ')}."
              end

              def absence_exceeds_pattern?(agent_id)
                return false unless agent_id

                if defined?(Legion::Extensions::Agentic::Memory::CommunicationPattern::Runners::CommunicationPattern)
                  begin
                    runner = Object.new
                    runner.extend(Legion::Extensions::Agentic::Memory::CommunicationPattern::Runners::CommunicationPattern)
                    stats = runner.partner_stats(agent_id: agent_id)
                    return false unless stats.is_a?(Hash)

                    avg_gap = stats[:average_gap_seconds] || stats[:avg_gap]
                    return false unless avg_gap&.positive?

                    last_interaction = stats[:last_interaction_at]
                    return false unless last_interaction

                    current_gap = Time.now - Time.parse(last_interaction.to_s)
                    return current_gap > (avg_gap * 2.0)
                  rescue StandardError => _e
                    return false
                  end
                end

                absence_exceeds_pattern_from_observations?(agent_id)
              end

              def absence_exceeds_pattern_from_observations?(agent_id)
                store = apollo_local_store
                return false unless store

                result = store.query(text: 'communication_pattern',
                                     tags: ['bond', 'communication_pattern', agent_id.to_s])
                return false unless result[:success] && result[:results]&.any?

                data = deserialize(result[:results].first[:content])
                return false unless data.is_a?(Hash)

                avg_gap = (data[:average_gap_seconds] || data[:avg_gap])&.to_f
                return false unless avg_gap&.positive?

                last_str = data[:last_interaction_at]
                return false unless last_str

                current_gap = Time.now - Time.parse(last_str.to_s)
                current_gap > (avg_gap * 2.0)
              rescue StandardError => _e
                false
              end

              def deserialize(content)
                parsed = defined?(Legion::JSON) ? Legion::JSON.parse(content) : ::JSON.parse(content, symbolize_names: true)
                parsed.is_a?(Hash) ? parsed.transform_keys(&:to_sym) : {}
              rescue StandardError => _e
                {}
              end
            end
          end
        end
      end
    end
  end
end
