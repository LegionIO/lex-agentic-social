# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Agentic
      module Social
        module Conflict
          module Actor
            class StaleCheck < Legion::Extensions::Actors::Every
              def runner_class
                Legion::Extensions::Agentic::Social::Conflict::Runners::Conflict
              end

              def runner_function
                'check_stale_conflicts'
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
