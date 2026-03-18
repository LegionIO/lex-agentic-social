# frozen_string_literal: true

require 'legion/extensions/agentic/social/governance/helpers/layers'
require 'legion/extensions/agentic/social/governance/helpers/proposal'
require 'legion/extensions/agentic/social/governance/runners/governance'

module Legion
  module Extensions
    module Agentic
      module Social
        module Governance
          class Client
            include Runners::Governance

            def initialize(**)
              @proposal_store = Helpers::Proposal.new
            end

            private

            attr_reader :proposal_store
          end
        end
      end
    end
  end
end
