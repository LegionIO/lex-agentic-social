# frozen_string_literal: true

require 'legion/extensions/agentic/social/apprenticeship/helpers/apprenticeship_model'
require 'legion/extensions/agentic/social/apprenticeship/helpers/apprenticeship'
require 'legion/extensions/agentic/social/apprenticeship/helpers/apprenticeship_engine'
require 'legion/extensions/agentic/social/apprenticeship/runners/cognitive_apprenticeship'

module Legion
  module Extensions
    module Agentic
      module Social
        module Apprenticeship
          class Client
            include Runners::CognitiveApprenticeship

            def initialize(**)
              @engine = Helpers::ApprenticeshipEngine.new
            end

            private

            attr_reader :engine
          end
        end
      end
    end
  end
end
