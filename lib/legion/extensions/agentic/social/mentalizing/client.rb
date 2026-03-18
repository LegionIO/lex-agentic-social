# frozen_string_literal: true

require 'legion/extensions/agentic/social/mentalizing/helpers/constants'
require 'legion/extensions/agentic/social/mentalizing/helpers/belief_attribution'
require 'legion/extensions/agentic/social/mentalizing/helpers/mental_model'
require 'legion/extensions/agentic/social/mentalizing/runners/mentalizing'

module Legion
  module Extensions
    module Agentic
      module Social
        module Mentalizing
          class Client
            include Runners::Mentalizing

            def initialize(**)
              @mental_model = Helpers::MentalModel.new
            end

            private

            attr_reader :mental_model
          end
        end
      end
    end
  end
end
