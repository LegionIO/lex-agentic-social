# frozen_string_literal: true

require_relative 'moral_reasoning/version'
require_relative 'moral_reasoning/helpers/constants'
require_relative 'moral_reasoning/helpers/moral_foundation'
require_relative 'moral_reasoning/helpers/dilemma'
require_relative 'moral_reasoning/helpers/moral_engine'
require_relative 'moral_reasoning/helpers/llm_enhancer'
require_relative 'moral_reasoning/runners/moral_reasoning'
require_relative 'moral_reasoning/client'

module Legion
  module Extensions
    module Agentic
      module Social
        module MoralReasoning
        end
      end
    end
  end
end
