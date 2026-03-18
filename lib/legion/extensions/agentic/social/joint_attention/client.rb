# frozen_string_literal: true

require 'legion/extensions/agentic/social/joint_attention/helpers/constants'
require 'legion/extensions/agentic/social/joint_attention/helpers/attention_target'
require 'legion/extensions/agentic/social/joint_attention/helpers/joint_focus_manager'
require 'legion/extensions/agentic/social/joint_attention/runners/joint_attention'

module Legion
  module Extensions
    module Agentic
      module Social
        module JointAttention
          class Client
            include Runners::JointAttention

            def initialize(joint_focus_manager: nil, **)
              @joint_focus_manager = joint_focus_manager || Helpers::JointFocusManager.new
            end

            private

            attr_reader :joint_focus_manager
          end
        end
      end
    end
  end
end
