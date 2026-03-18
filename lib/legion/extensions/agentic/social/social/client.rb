# frozen_string_literal: true

require 'legion/extensions/agentic/social/social/helpers/constants'
require 'legion/extensions/agentic/social/social/helpers/social_graph'
require 'legion/extensions/agentic/social/social/runners/social'

module Legion
  module Extensions
    module Agentic
      module Social
        module Social
          class Client
            include Runners::Social

            attr_reader :social_graph

            def initialize(social_graph: nil, **)
              @social_graph = social_graph || Helpers::SocialGraph.new
            end
          end
        end
      end
    end
  end
end
