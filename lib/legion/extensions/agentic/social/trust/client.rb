# frozen_string_literal: true

require 'legion/extensions/agentic/social/trust/helpers/trust_model'
require 'legion/extensions/agentic/social/trust/helpers/trust_map'
require 'legion/extensions/agentic/social/trust/runners/trust'

module Legion
  module Extensions
    module Agentic
      module Social
        module Trust
          class Client
            include Runners::Trust

            def initialize(**)
              @trust_map = Helpers::TrustMap.new
            end

            private

            attr_reader :trust_map
          end
        end
      end
    end
  end
end
