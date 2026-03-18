# frozen_string_literal: true

require 'legion/extensions/agentic/social/trust/version'
require 'legion/extensions/agentic/social/trust/helpers/trust_model'
require 'legion/extensions/agentic/social/trust/helpers/trust_map'
require 'legion/extensions/agentic/social/trust/runners/trust'
require 'legion/extensions/agentic/social/trust/client'

module Legion
  module Extensions
    module Agentic
      module Social
        module Trust
        end
      end
    end

    if defined?(Legion::Data::Local)
      Legion::Data::Local.register_migrations(
        name: :trust,
        path: File.join(__dir__, 'trust', 'local_migrations')
      )
    end
  end
end
