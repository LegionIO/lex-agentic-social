# frozen_string_literal: true

require 'legion/extensions/agentic/social/consent/version'
require 'legion/extensions/agentic/social/consent/helpers/tiers'
require 'legion/extensions/agentic/social/consent/helpers/consent_map'
require 'legion/extensions/agentic/social/consent/runners/consent'
require 'legion/extensions/agentic/social/consent/client'

module Legion
  module Extensions
    module Agentic
      module Social
        module Consent
        end
      end
    end

    if defined?(Legion::Data::Local)
      Legion::Data::Local.register_migrations(
        name: :consent,
        path: File.join(__dir__, 'consent', 'local_migrations')
      )
    end
  end
end
