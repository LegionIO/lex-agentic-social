# frozen_string_literal: true

require_relative 'social/version'
require_relative 'social/mirror'
require_relative 'social/entrainment'
require_relative 'social/symbiosis'
require_relative 'social/apprenticeship'
require_relative 'social/theory_of_mind'
require_relative 'social/mentalizing'
require_relative 'social/social'
require_relative 'social/social_learning'
require_relative 'social/perspective_shifting'
require_relative 'social/trust'
require_relative 'social/conflict'
require_relative 'social/conscience'
require_relative 'social/consent'
require_relative 'social/moral_reasoning'
require_relative 'social/governance'
require_relative 'social/joint_attention'
require_relative 'social/mirror_system'
require_relative 'social/attachment'

module Legion
  module Extensions
    module Agentic
      module Social
        extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false

        def self.remote_invocable?
          false
        end
      end
    end
  end
end
