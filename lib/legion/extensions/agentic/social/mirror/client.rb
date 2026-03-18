# frozen_string_literal: true

require 'legion/extensions/agentic/social/mirror/helpers/constants'
require 'legion/extensions/agentic/social/mirror/helpers/mirror_event'
require 'legion/extensions/agentic/social/mirror/helpers/simulation'
require 'legion/extensions/agentic/social/mirror/helpers/mirror_engine'
require 'legion/extensions/agentic/social/mirror/runners/observe'
require 'legion/extensions/agentic/social/mirror/runners/simulate'
require 'legion/extensions/agentic/social/mirror/runners/resonance'

module Legion
  module Extensions
    module Agentic
      module Social
        module Mirror
          class Client
            include Runners::Observe
            include Runners::Simulate
            include Runners::Resonance

            def initialize(**)
              @mirror_engine = Helpers::MirrorEngine.new
            end

            private

            attr_reader :mirror_engine
          end
        end
      end
    end
  end
end
