# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Governance
          module Runners
            module ShadowAi # rubocop:disable Legion/Extension/RunnerIncludeHelpers
              def scan_unregistered_extensions(**)
                installed = Bundler.load.specs.select { |s| s.name.start_with?('lex-') }.map(&:name)
                registered = registered_extension_names

                unregistered = installed - registered
                { installed: installed.size, registered: registered.size, unregistered: unregistered }
              rescue StandardError => e
                { installed: 0, registered: 0, unregistered: [], error: e.message }
              end

              def check_llm_bypass_indicators(**)
                indicators = []
                indicators << :direct_openai_key if ENV.key?('OPENAI_API_KEY') && !provider_enabled?(:openai)
                indicators << :direct_anthropic_key if ENV.key?('ANTHROPIC_API_KEY') && !provider_enabled?(:anthropic)
                { indicators: indicators, bypassed: !indicators.empty? }
              end

              def check_airb_compliance(**)
                return { checked: 0, source: :unavailable } unless defined?(Legion::Data::Model::DigitalWorker)

                workers = Legion::Data::Model::DigitalWorker.where(lifecycle_state: 'active').all
                non_compliant = workers.select do |w|
                  risk = w.respond_to?(:risk_tier) ? w.risk_tier : nil
                  %w[high critical].include?(risk) && w.respond_to?(:airb_status) && w.airb_status != 'approved'
                end

                { checked: workers.size, compliant: workers.size - non_compliant.size,
                  non_compliant: non_compliant.map(&:worker_id) }
              rescue StandardError => e
                { checked: 0, error: e.message }
              end

              def full_scan(**)
                extensions = scan_unregistered_extensions
                bypass = check_llm_bypass_indicators
                compliance = check_airb_compliance

                has_issues = extensions[:unregistered]&.any? || bypass[:bypassed] || compliance[:non_compliant]&.any?
                emit_shadow_event(extensions, bypass, compliance) if has_issues

                { extensions: extensions, bypass: bypass, compliance: compliance, issues_found: has_issues }
              end

              private

              def registered_extension_names
                return [] unless defined?(Legion::Data) && Legion::Data.respond_to?(:connection)

                conn = Legion::Data.connection
                return [] unless conn&.table_exists?(:extension_registry)

                conn[:extension_registry].select_map(:gem_name)
              rescue StandardError => _e
                []
              end

              def provider_enabled?(provider)
                llm = Legion::Settings[:llm]
                return false unless llm.is_a?(Hash)

                providers = llm[:providers]
                return false unless providers.is_a?(Hash)

                providers.dig(provider, :enabled) == true
              rescue StandardError => _e
                false
              end

              def emit_shadow_event(extensions, bypass, compliance)
                return unless defined?(Legion::Events)

                Legion::Events.emit('governance.shadow_ai_detected', {
                                      unregistered:  extensions[:unregistered],
                                      bypass:        bypass[:indicators],
                                      non_compliant: compliance[:non_compliant]
                                    })
              end
            end
          end
        end
      end
    end
  end
end
