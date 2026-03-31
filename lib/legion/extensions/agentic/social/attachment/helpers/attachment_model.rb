# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Attachment
          module Helpers
            class AttachmentModel
              attr_reader :agent_id, :attachment_strength, :attachment_style,
                          :bond_stage, :separation_tolerance, :interaction_count

              def initialize(agent_id:)
                @agent_id             = agent_id
                @attachment_strength  = 0.0
                @attachment_style     = :secure
                @bond_stage           = :initial
                @separation_tolerance = Constants::BASE_SEPARATION_TOLERANCE
                @interaction_count    = 0
              end

              def update_from_signals(opts = {})
                frequency_score      = opts.fetch(:frequency_score, 0.0)
                reciprocity_score    = opts.fetch(:reciprocity_score, 0.0)
                prediction_accuracy  = opts.fetch(:prediction_accuracy, 0.0)
                direct_address_ratio = opts.fetch(:direct_address_ratio, 0.0)
                channel_consistency  = opts.fetch(:channel_consistency, 0.0)

                raw = (frequency_score * Constants::FREQUENCY_WEIGHT) +
                      (reciprocity_score * Constants::RECIPROCITY_WEIGHT) +
                      (prediction_accuracy * Constants::PREDICTION_ACCURACY_WEIGHT) +
                      (direct_address_ratio * Constants::DIRECT_ADDRESS_WEIGHT) +
                      (channel_consistency * Constants::CHANNEL_CONSISTENCY_WEIGHT)

                @attachment_strength = if @interaction_count.zero?
                                         raw.clamp(0.0, 1.0)
                                       else
                                         alpha = Constants::STRENGTH_ALPHA
                                         ((alpha * raw) + ((1.0 - alpha) * @attachment_strength)).clamp(0.0, 1.0)
                                       end
                @interaction_count += 1
              end

              def update_stage!
                new_stage = derive_stage
                return if Constants::BOND_STAGES.index(new_stage) <= Constants::BOND_STAGES.index(@bond_stage)

                @bond_stage = new_stage
                @separation_tolerance = Constants::BASE_SEPARATION_TOLERANCE +
                                        Constants::SEPARATION_TOLERANCE_GROWTH.fetch(@bond_stage, 0)
              end

              def derive_style!(opts = {})
                frequency_variance    = opts.fetch(:frequency_variance, 0.0)
                reciprocity_imbalance = opts.fetch(:reciprocity_imbalance, 0.0)
                frequency             = opts.fetch(:frequency, 0.0)
                direct_address_ratio  = opts.fetch(:direct_address_ratio, 0.0)
                thresholds = Constants::STYLE_THRESHOLDS
                @attachment_style = if frequency_variance > thresholds[:anxious_frequency_variance] &&
                                       reciprocity_imbalance > thresholds[:anxious_reciprocity_imbalance]
                                      :anxious
                                    elsif frequency < thresholds[:avoidant_frequency] &&
                                          direct_address_ratio < thresholds[:avoidant_direct_address]
                                      :avoidant
                                    else
                                      :secure
                                    end
              end

              def to_h
                { agent_id: @agent_id, attachment_strength: @attachment_strength,
                  attachment_style: @attachment_style, bond_stage: @bond_stage,
                  separation_tolerance: @separation_tolerance, interaction_count: @interaction_count }
              end

              def self.from_h(hash)
                model = new(agent_id: hash[:agent_id])
                model.instance_variable_set(:@attachment_strength, hash[:attachment_strength].to_f)
                model.instance_variable_set(:@attachment_style, hash[:attachment_style]&.to_sym || :secure)
                model.instance_variable_set(:@bond_stage, hash[:bond_stage]&.to_sym || :initial)
                model.instance_variable_set(:@separation_tolerance, hash[:separation_tolerance]&.to_i || 3)
                model.instance_variable_set(:@interaction_count, hash[:interaction_count].to_i)
                model
              end

              private

              def derive_stage
                Constants::STAGE_THRESHOLDS.each_key.reverse_each do |stage|
                  threshold = Constants::STAGE_THRESHOLDS[stage]
                  return stage if @interaction_count >= threshold[:interactions] &&
                                  @attachment_strength >= threshold[:strength]
                end
                :initial
              end
            end
          end
        end
      end
    end
  end
end
