# frozen_string_literal: true

require 'legion/extensions/agentic/social/theory_of_mind/helpers/constants'
require 'legion/extensions/agentic/social/theory_of_mind/helpers/agent_model'
require 'legion/extensions/agentic/social/theory_of_mind/helpers/mental_state_tracker'
require 'legion/extensions/agentic/social/theory_of_mind/runners/theory_of_mind'

module Legion
  module Extensions
    module Agentic
      module Social
        module TheoryOfMind
          class Client
            include Runners::TheoryOfMind

            attr_reader :tracker

            def initialize(tracker: nil, **)
              @tracker = tracker || Helpers::MentalStateTracker.new
            end
          end
        end
      end
    end
  end
end
