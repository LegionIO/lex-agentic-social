# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module PerspectiveShifting
          module Runners
            module PerspectiveShifting
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              # --- Perspective management ---

              def add_perspective(name:, type: :stakeholder, priorities: [], empathy: Helpers::Constants::DEFAULT_EMPATHY,
                                  bias: nil, expertise_domains: [], engine: nil, **)
                eng    = engine || shifting_engine
                result = eng.add_perspective(name: name, type: type, priorities: priorities,
                                             empathy: empathy, bias: bias, expertise_domains: expertise_domains)
                return { success: false, error: result[:error] } if result.is_a?(Hash) && result[:error]

                log.debug "[perspective_shifting] added perspective name=#{name} type=#{type} id=#{result.id[0..7]}"
                { success: true, perspective: result.to_h }
              end

              def list_perspectives(engine: nil, **)
                eng   = engine || shifting_engine
                persp = eng.perspectives.values.map(&:to_h)
                log.debug "[perspective_shifting] list_perspectives count=#{persp.size}"
                { success: true, perspectives: persp, count: persp.size }
              end

              def get_perspective(perspective_id:, engine: nil, **)
                eng   = engine || shifting_engine
                persp = eng.perspectives[perspective_id]
                if persp
                  { success: true, found: true, perspective: persp.to_h }
                else
                  log.debug "[perspective_shifting] perspective not found id=#{perspective_id[0..7]}"
                  { success: false, found: false }
                end
              end

              # --- Situation management ---

              def add_situation(content:, engine: nil, **)
                eng    = engine || shifting_engine
                result = eng.add_situation(content: content)
                return { success: false, error: result[:error] } if result.is_a?(Hash) && result[:error]

                log.debug "[perspective_shifting] added situation id=#{result[:id][0..7]}"
                { success: true, situation_id: result[:id], content: result[:content] }
              end

              def list_situations(engine: nil, **)
                eng  = engine || shifting_engine
                sits = eng.situations.values.map { |s| s.merge(views: s[:views].map(&:to_h)) }
                log.debug "[perspective_shifting] list_situations count=#{sits.size}"
                { success: true, situations: sits, count: sits.size }
              end

              # --- View generation and retrieval ---

              def generate_view(situation_id:, perspective_id:, valence: 0.0,
                                concerns: [], opportunities: [], confidence: 0.5, engine: nil, **)
                eng    = engine || shifting_engine
                result = eng.generate_view(
                  situation_id:   situation_id,
                  perspective_id: perspective_id,
                  valence:        valence,
                  concerns:       concerns,
                  opportunities:  opportunities,
                  confidence:     confidence
                )
                return { success: false, error: result[:error] } if result.is_a?(Hash) && result[:error]

                log.debug "[perspective_shifting] generated view id=#{result.id[0..7]} " \
                          "valence=#{result.valence.round(2)}"
                { success: true, view: result.to_h }
              end

              def views_for_situation(situation_id:, engine: nil, **)
                eng   = engine || shifting_engine
                views = eng.views_for_situation(situation_id: situation_id)
                log.debug "[perspective_shifting] views_for_situation id=#{situation_id[0..7]} count=#{views.size}"
                { success: true, views: views.map(&:to_h), count: views.size }
              end

              # --- Analysis ---

              def perspective_agreement(situation_id:, engine: nil, **)
                eng       = engine || shifting_engine
                score     = eng.perspective_agreement(situation_id: situation_id)
                label     = Helpers::Constants.agreement_label(score)
                log.debug "[perspective_shifting] agreement situation=#{situation_id[0..7]} score=#{score.round(2)} label=#{label}"
                { success: true, situation_id: situation_id, agreement: score, label: label }
              end

              def blind_spots(situation_id:, engine: nil, **)
                eng   = engine || shifting_engine
                spots = eng.blind_spots(situation_id: situation_id)
                log.debug "[perspective_shifting] blind_spots situation=#{situation_id[0..7]} count=#{spots.size}"
                { success: true, situation_id: situation_id, blind_spots: spots, count: spots.size }
              end

              def coverage_score(situation_id:, engine: nil, **)
                eng   = engine || shifting_engine
                score = eng.coverage_score(situation_id: situation_id)
                label = Helpers::Constants.coverage_label(score)
                log.debug "[perspective_shifting] coverage situation=#{situation_id[0..7]} score=#{score.round(2)} label=#{label}"
                { success: true, situation_id: situation_id, coverage: score, label: label }
              end

              def dominant_view(situation_id:, engine: nil, **)
                eng  = engine || shifting_engine
                view = eng.dominant_view(situation_id: situation_id)
                if view
                  log.debug "[perspective_shifting] dominant_view situation=#{situation_id[0..7]} confidence=#{view.confidence.round(2)}"
                  { success: true, found: true, view: view.to_h }
                else
                  { success: true, found: false }
                end
              end

              def synthesize(situation_id:, engine: nil, **)
                eng    = engine || shifting_engine
                result = eng.synthesize(situation_id: situation_id)
                return { success: false, error: result[:error] } if result[:error]

                log.info "[perspective_shifting] synthesized situation=#{situation_id[0..7]} " \
                         "valence=#{result[:weighted_valence].round(2)} views=#{result[:view_count]}"
                result.merge(success: true)
              end

              def most_divergent_pair(situation_id:, engine: nil, **)
                eng  = engine || shifting_engine
                pair = eng.most_divergent_pair(situation_id: situation_id)
                unless pair
                  log.debug '[perspective_shifting] most_divergent_pair: not enough views'
                  return { success: true, found: false }
                end

                divergence = (pair[0].valence - pair[1].valence).abs.round(10)
                log.debug "[perspective_shifting] most_divergent_pair divergence=#{divergence.round(2)}"
                { success: true, found: true, views: pair.map(&:to_h), divergence: divergence }
              end

              def engine_status(engine: nil, **)
                eng = engine || shifting_engine
                log.debug '[perspective_shifting] engine_status'
                { success: true }.merge(eng.to_h)
              end

              private

              def shifting_engine
                @shifting_engine ||= Helpers::ShiftingEngine.new
              end
            end
          end
        end
      end
    end
  end
end
