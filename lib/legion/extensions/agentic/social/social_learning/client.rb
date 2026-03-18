# frozen_string_literal: true

require 'legion/extensions/agentic/social/social_learning/helpers/constants'
require 'legion/extensions/agentic/social/social_learning/helpers/observed_behavior'
require 'legion/extensions/agentic/social/social_learning/helpers/model_agent'
require 'legion/extensions/agentic/social/social_learning/helpers/social_learning_engine'
require 'legion/extensions/agentic/social/social_learning/runners/social_learning'

module Legion
  module Extensions
    module Agentic
      module Social
        module SocialLearning
          class Client
            include Runners::SocialLearning

            def initialize(engine: nil)
              @engine = engine || Helpers::SocialLearningEngine.new
            end
          end
        end
      end
    end
  end
end
