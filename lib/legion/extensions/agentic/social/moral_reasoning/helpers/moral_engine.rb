# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module MoralReasoning
          module Helpers
            module FrameworkEvaluators
              CARE_FOUNDATIONS     = %i[care fairness sanctity].freeze
              DUTY_FOUNDATIONS     = %i[authority loyalty].freeze
              JUSTICE_FOUNDATIONS  = %i[fairness liberty].freeze
              RIGHTS_FOUNDATIONS   = %i[liberty fairness authority].freeze

              private

              def evaluate_by_utility(dilemma)
                rank_options(dilemma) do |option|
                  option.fetch(:foundations, []).sum { |fid| @foundations[fid]&.weight.to_f }
                end
              end

              def evaluate_by_duty(dilemma)
                rank_options(dilemma) do |option|
                  option.fetch(:foundations, []).count { |fid| DUTY_FOUNDATIONS.include?(fid) }.to_f
                end
              end

              def evaluate_by_virtue(dilemma)
                rank_options(dilemma) do |option|
                  option.fetch(:foundations, []).count { |fid| CARE_FOUNDATIONS.include?(fid) }.to_f
                end
              end

              def evaluate_by_care(dilemma)
                rank_options(dilemma) do |option|
                  option.fetch(:foundations, []).count { |fid| fid == :care }.to_f
                end
              end

              def evaluate_by_justice(dilemma)
                rank_options(dilemma) do |option|
                  option.fetch(:foundations, []).count { |fid| JUSTICE_FOUNDATIONS.include?(fid) }.to_f
                end
              end

              def evaluate_by_rights(dilemma)
                rank_options(dilemma) do |option|
                  option.fetch(:foundations, []).count { |fid| RIGHTS_FOUNDATIONS.include?(fid) }.to_f
                end
              end

              def rank_options(dilemma)
                scored = dilemma.options.map do |option|
                  score = yield(option)
                  { id: option[:id], description: option[:description], score: score }
                end
                scored.sort_by { |r| -r[:score] }
              end
            end

            class MoralEngine
              include Constants
              include FrameworkEvaluators

              KOHLBERG_STAGE_DESCRIPTIONS = {
                obedience:        'Avoid punishment; obey authority unconditionally',
                self_interest:    'Act for direct reward; reciprocal exchange',
                conformity:       'Conform to social norms; be a good person',
                law_and_order:    'Follow rules, laws, and authority to maintain social order',
                social_contract:  'Uphold democratic principles; greatest good for greatest number',
                universal_ethics: 'Follow self-chosen universal ethical principles'
              }.freeze

              FRAMEWORK_STRATEGIES = {
                utilitarian:   :evaluate_by_utility,
                deontological: :evaluate_by_duty,
                virtue:        :evaluate_by_virtue,
                care:          :evaluate_by_care,
                justice:       :evaluate_by_justice,
                rights:        :evaluate_by_rights
              }.freeze

              attr_reader :stage, :dilemmas, :principles, :history

              def initialize
                @foundations = MORAL_FOUNDATIONS.to_h { |f| [f, MoralFoundation.new(id: f)] }
                @principles  = []
                @dilemmas    = {}
                @stage       = :social_contract
                @history     = []
              end

              def evaluate_action(action:, affected_foundations:, domain: :general)
                score = score_foundations(affected_foundations)
                normalized = affected_foundations.empty? ? 0.0 : score / affected_foundations.size
                add_history(type: :evaluation, action: action, domain: domain, score: normalized)
                { action: action, domain: domain, score: normalized, foundations: affected_foundations }
              end

              def pose_dilemma(description:, options:, domain: :general, severity: 0.5)
                return { success: false, reason: :max_dilemmas_reached } if @dilemmas.size >= MAX_DILEMMAS

                id = generate_id('dilemma')
                dilemma = Dilemma.new(id: id, description: description, options: options,
                                      domain: domain, severity: severity)
                @dilemmas[id] = dilemma
                { success: true, dilemma: dilemma.to_h }
              end

              def resolve_dilemma(dilemma_id:, option_id:, reasoning:, framework:)
                dilemma = @dilemmas[dilemma_id]
                return { success: false, reason: :not_found } unless dilemma
                return { success: false, reason: :already_resolved } if dilemma.resolved?

                chosen = dilemma.options.find { |o| o[:id] == option_id }
                return { success: false, reason: :invalid_option } unless chosen

                dilemma.resolve(option_id: option_id, reasoning: reasoning, framework: framework)
                reinforce_chosen_foundations(chosen)
                weaken_unchosen_foundations(dilemma.options, option_id)
                add_history(type: :resolution, dilemma_id: dilemma_id, option_id: option_id,
                            framework: framework, severity: dilemma.severity)
                { success: true, dilemma: dilemma.to_h }
              end

              def apply_framework(dilemma_id:, framework:)
                dilemma = @dilemmas[dilemma_id]
                return { success: false, reason: :not_found } unless dilemma
                return { success: false, reason: :unknown_framework } unless ETHICAL_FRAMEWORKS.include?(framework)

                strategy  = FRAMEWORK_STRATEGIES.fetch(framework)
                rankings  = send(strategy, dilemma)
                { success: true, dilemma_id: dilemma_id, framework: framework, rankings: rankings }
              end

              def add_principle(name:, description:, foundation:, weight: DEFAULT_WEIGHT)
                return { success: false, reason: :max_principles_reached } if @principles.size >= MAX_PRINCIPLES
                return { success: false, reason: :unknown_foundation } unless MORAL_FOUNDATIONS.include?(foundation)

                principle = {
                  id:          generate_id('principle'),
                  name:        name,
                  description: description,
                  foundation:  foundation,
                  weight:      weight.clamp(WEIGHT_FLOOR, WEIGHT_CEILING),
                  created_at:  Time.now.utc
                }
                @principles << principle
                { success: true, principle: principle }
              end

              def moral_development
                resolved = resolved_dilemmas
                return { advanced: false, stage: @stage, reason: :insufficient_resolutions } if resolved.size < 3

                avg_severity = resolved.sum(&:severity) / resolved.size.to_f
                complexity_met = avg_severity >= 0.4 && resolved.size >= 5
                current_idx = KOHLBERG_STAGES.index(@stage)

                if complexity_met && current_idx < KOHLBERG_STAGES.size - 1
                  @stage = KOHLBERG_STAGES[current_idx + 1]
                  { advanced: true, stage: @stage, previous_stage: KOHLBERG_STAGES[current_idx] }
                else
                  { advanced: false, stage: @stage, reason: :complexity_threshold_not_met }
                end
              end

              def foundation_profile
                @foundations.transform_values(&:to_h)
              end

              def stage_info
                level = KOHLBERG_LEVELS.find { |_, stages| stages.include?(@stage) }&.first
                { stage: @stage, level: level, description: KOHLBERG_STAGE_DESCRIPTIONS.fetch(@stage, 'Unknown') }
              end

              def unresolved_dilemmas
                @dilemmas.values.reject(&:resolved?)
              end

              def resolved_dilemmas
                @dilemmas.values.select(&:resolved?)
              end

              def decay_all
                @foundations.each_value(&:decay)
              end

              def to_h
                {
                  stage:               @stage,
                  total_dilemmas:      @dilemmas.size,
                  resolved_dilemmas:   resolved_dilemmas.size,
                  unresolved_dilemmas: unresolved_dilemmas.size,
                  principles:          @principles.size,
                  history_entries:     @history.size,
                  foundation_profile:  foundation_profile
                }
              end

              private

              def score_foundations(affected_foundations)
                affected_foundations.sum do |fid|
                  foundation = @foundations.fetch(fid, nil)
                  next 0.0 unless foundation

                  foundation.weight * foundation.sensitivity
                end
              end

              def reinforce_chosen_foundations(chosen_option)
                chosen_option.fetch(:foundations, []).each do |fid|
                  @foundations[fid]&.reinforce(amount: chosen_option.fetch(:severity, 1.0))
                end
              end

              def weaken_unchosen_foundations(options, chosen_id)
                options.reject { |o| o[:id] == chosen_id }.each do |option|
                  option.fetch(:foundations, []).each { |fid| @foundations[fid]&.weaken(amount: 0.5) }
                end
              end

              def add_history(entry)
                @history << entry.merge(timestamp: Time.now.utc)
                @history.shift if @history.size > MAX_HISTORY
              end

              def generate_id(prefix)
                "#{prefix}_#{Time.now.utc.to_f}_#{rand(1000)}"
              end
            end
          end
        end
      end
    end
  end
end
