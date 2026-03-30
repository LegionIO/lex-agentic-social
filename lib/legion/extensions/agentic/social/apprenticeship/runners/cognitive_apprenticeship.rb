# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Apprenticeship
          module Runners
            module CognitiveApprenticeship
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def create_apprenticeship(skill_name:, domain:, mentor_id:, apprentice_id:, **)
                return { success: false, reason: :param_too_short } if [skill_name, domain, mentor_id, apprentice_id].any? { |p| p.to_s.length < 3 }

                appr = engine.create_apprenticeship(
                  skill_name:    skill_name,
                  domain:        domain,
                  mentor_id:     mentor_id,
                  apprentice_id: apprentice_id
                )

                if appr
                  log.info "[cognitive_apprenticeship] created id=#{appr.id} skill=#{skill_name} domain=#{domain}"
                  { success: true, apprenticeship: appr.to_h }
                else
                  log.warn '[cognitive_apprenticeship] create failed: capacity reached'
                  { success: false, reason: :capacity_reached }
                end
              end

              def conduct_apprenticeship_session(apprenticeship_id:, method:, success:, **)
                return { success: false, reason: :invalid_method } unless Helpers::ApprenticeshipModel::METHODS.include?(method.to_sym)

                appr = engine.conduct_session(
                  apprenticeship_id: apprenticeship_id,
                  method:            method.to_sym,
                  success:           success
                )

                if appr
                  log.debug "[cognitive_apprenticeship] session id=#{apprenticeship_id} method=#{method} " \
                            "success=#{success} mastery=#{appr.mastery.round(3)}"
                  { success: true, apprenticeship: appr.to_h }
                else
                  { success: false, reason: :not_found }
                end
              end

              def recommend_apprenticeship_method(apprenticeship_id:, **)
                method = engine.recommend_method(apprenticeship_id: apprenticeship_id)

                if method
                  log.debug "[cognitive_apprenticeship] recommend id=#{apprenticeship_id} method=#{method}"
                  { success: true, apprenticeship_id: apprenticeship_id, recommended_method: method }
                else
                  { success: false, reason: :not_found }
                end
              end

              def graduated_apprenticeships(**)
                list = engine.graduated_apprenticeships
                log.debug "[cognitive_apprenticeship] graduated count=#{list.size}"
                { success: true, apprenticeships: list.map(&:to_h), count: list.size }
              end

              def active_apprenticeships(**)
                list = engine.active_apprenticeships
                log.debug "[cognitive_apprenticeship] active count=#{list.size}"
                { success: true, apprenticeships: list.map(&:to_h), count: list.size }
              end

              def mentor_apprenticeships(mentor_id:, **)
                list = engine.by_mentor(mentor_id: mentor_id)
                log.debug "[cognitive_apprenticeship] mentor=#{mentor_id} count=#{list.size}"
                { success: true, mentor_id: mentor_id, apprenticeships: list.map(&:to_h), count: list.size }
              end

              def apprentice_apprenticeships(apprentice_id:, **)
                list = engine.by_apprentice(apprentice_id: apprentice_id)
                log.debug "[cognitive_apprenticeship] apprentice=#{apprentice_id} count=#{list.size}"
                { success: true, apprentice_id: apprentice_id, apprenticeships: list.map(&:to_h), count: list.size }
              end

              def domain_apprenticeships(domain:, **)
                list = engine.by_domain(domain: domain)
                log.debug "[cognitive_apprenticeship] domain=#{domain} count=#{list.size}"
                { success: true, domain: domain, apprenticeships: list.map(&:to_h), count: list.size }
              end

              def update_cognitive_apprenticeship(apprenticeship_id:, method:, success:, **)
                conduct_apprenticeship_session(apprenticeship_id: apprenticeship_id, method: method, success: success)
              end

              def cognitive_apprenticeship_stats(**)
                stats = engine.to_h
                log.debug "[cognitive_apprenticeship] stats=#{stats.inspect}"
                { success: true }.merge(stats)
              end

              private

              def engine
                @engine ||= Helpers::ApprenticeshipEngine.new
              end
            end
          end
        end
      end
    end
  end
end
