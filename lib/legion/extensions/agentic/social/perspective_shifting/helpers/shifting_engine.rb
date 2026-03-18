# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module PerspectiveShifting
          module Helpers
            class ShiftingEngine
              attr_reader :perspectives, :situations

              def initialize
                @perspectives = {}
                @situations   = {}
              end

              def add_perspective(name:, type: :stakeholder, priorities: [], empathy: Constants::DEFAULT_EMPATHY,
                                  bias: nil, expertise_domains: [])
                return { error: :too_many_perspectives } if @perspectives.size >= Constants::MAX_PERSPECTIVES
                return { error: :invalid_type } unless Constants::PERSPECTIVE_TYPES.include?(type)

                p = Perspective.new(
                  name:              name,
                  perspective_type:  type,
                  priorities:        priorities,
                  expertise_domains: expertise_domains,
                  empathy_level:     empathy,
                  bias_toward:       bias
                )
                @perspectives[p.id] = p
                p
              end

              def add_situation(content:)
                return { error: :too_many_situations } if @situations.size >= Constants::MAX_SITUATIONS

                id = SecureRandom.uuid
                @situations[id] = { id: id, content: content, views: [], created_at: Time.now.utc }
                @situations[id]
              end

              def generate_view(situation_id:, perspective_id:, valence: 0.0,
                                concerns: [], opportunities: [], confidence: 0.5)
                situation = @situations[situation_id]
                perspective = @perspectives[perspective_id]

                return { error: :situation_not_found } unless situation
                return { error: :perspective_not_found } unless perspective
                return { error: :too_many_views } if situation[:views].size >= Constants::MAX_VIEWS_PER_SITUATION

                view = PerspectiveView.new(
                  situation_id:   situation_id,
                  perspective_id: perspective_id,
                  valence:        valence,
                  concerns:       concerns,
                  opportunities:  opportunities,
                  confidence:     confidence
                )
                situation[:views] << view
                view
              end

              def views_for_situation(situation_id:)
                situation = @situations[situation_id]
                return [] unless situation

                situation[:views]
              end

              def perspective_agreement(situation_id:)
                views = views_for_situation(situation_id: situation_id)
                return 0.0 if views.size < Constants::MIN_PERSPECTIVES_FOR_SYNTHESIS

                valences = views.map(&:valence)
                mean     = valences.sum / valences.size.to_f
                variance = valences.sum { |v| (v - mean)**2 } / valences.size.to_f
                std_dev  = Math.sqrt(variance)

                # Agreement is inverse of normalized std_dev (max std_dev is 1.0 for symmetric ±1 distribution)
                (1.0 - std_dev).clamp(0.0, 1.0).round(10)
              end

              def blind_spots(situation_id:)
                views = views_for_situation(situation_id: situation_id)
                applied_ids = views.map(&:perspective_id).uniq
                applied_types = applied_ids.filter_map { |pid| @perspectives[pid]&.perspective_type }.uniq
                Constants::PERSPECTIVE_TYPES - applied_types
              end

              def coverage_score(situation_id:)
                views = views_for_situation(situation_id: situation_id)
                return 0.0 if @perspectives.empty?

                applied_count = views.map(&:perspective_id).uniq.size
                (applied_count.to_f / @perspectives.size).clamp(0.0, 1.0).round(10)
              end

              def dominant_view(situation_id:)
                views = views_for_situation(situation_id: situation_id)
                return nil if views.empty?

                views.max_by(&:confidence)
              end

              def synthesize(situation_id:)
                views = views_for_situation(situation_id: situation_id)
                return { error: :insufficient_views } if views.size < Constants::MIN_PERSPECTIVES_FOR_SYNTHESIS

                total_confidence = views.sum(&:confidence)
                return { error: :zero_confidence } if total_confidence.zero?

                weighted_valence = views.sum { |v| v.valence * v.confidence } / total_confidence
                all_concerns     = views.flat_map(&:concerns).uniq
                all_opportunities = views.flat_map(&:opportunities).uniq
                agreement = perspective_agreement(situation_id: situation_id)

                {
                  situation_id:     situation_id,
                  weighted_valence: weighted_valence.round(10),
                  concerns:         all_concerns,
                  opportunities:    all_opportunities,
                  agreement:        agreement.round(10),
                  agreement_label:  Constants.agreement_label(agreement),
                  view_count:       views.size,
                  coverage_score:   coverage_score(situation_id: situation_id),
                  coverage_label:   Constants.coverage_label(coverage_score(situation_id: situation_id))
                }
              end

              def most_divergent_pair(situation_id:)
                views = views_for_situation(situation_id: situation_id)
                return nil if views.size < 2

                max_diff = -1.0
                pair     = nil

                views.combination(2) do |a, b|
                  diff = (a.valence - b.valence).abs
                  if diff > max_diff
                    max_diff = diff
                    pair     = [a, b]
                  end
                end

                pair
              end

              def to_h
                {
                  perspective_count: @perspectives.size,
                  situation_count:   @situations.size,
                  perspectives:      @perspectives.values.map(&:to_h),
                  situations:        @situations.values.map do |s|
                    s.merge(views: s[:views].map(&:to_h))
                  end
                }
              end
            end
          end
        end
      end
    end
  end
end
