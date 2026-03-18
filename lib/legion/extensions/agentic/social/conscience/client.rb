# frozen_string_literal: true

require 'legion/extensions/agentic/social/conscience/helpers/constants'
require 'legion/extensions/agentic/social/conscience/helpers/moral_evaluator'
require 'legion/extensions/agentic/social/conscience/helpers/moral_store'
require 'legion/extensions/agentic/social/conscience/runners/conscience'

module Legion
  module Extensions
    module Agentic
      module Social
        module Conscience
          class Client
            include Runners::Conscience

            attr_reader :moral_store

            def initialize(moral_store: nil, **)
              @moral_store = moral_store || Helpers::MoralStore.new
            end
          end
        end
      end
    end
  end
end
