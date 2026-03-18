# frozen_string_literal: true

require 'legion/extensions/agentic/social/mirror_system/helpers/constants'
require 'legion/extensions/agentic/social/mirror_system/helpers/observed_behavior'
require 'legion/extensions/agentic/social/mirror_system/helpers/mirror_system'
require 'legion/extensions/agentic/social/mirror_system/runners/mirror'

module Legion
  module Extensions
    module Agentic
      module Social
        module MirrorSystem
          class Client
            include Runners::Mirror

            def initialize(mirror_system: nil, **)
              @mirror_system = mirror_system || Helpers::MirrorSystem.new
            end

            private

            attr_reader :mirror_system
          end
        end
      end
    end
  end
end
