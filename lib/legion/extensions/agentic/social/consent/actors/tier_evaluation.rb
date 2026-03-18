# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Agentic
      module Social
        module Consent
          module Actor
            class TierEvaluation < Legion::Extensions::Actors::Every
              def runner_class
                Legion::Extensions::Agentic::Social::Consent::Runners::Consent
              end

              def runner_function
                'evaluate_and_apply_tiers'
              end

              def time
                3600
              end

              def run_now?
                false
              end

              def use_runner?
                false
              end

              def check_subtask?
                false
              end

              def generate_task?
                false
              end
            end
          end
        end
      end
    end
  end
end
