# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Entrainment
          class Client
            include Runners::CognitiveEntrainment

            def initialize(engine: nil)
              @engine = engine || Helpers::EntrainmentEngine.new
            end
          end
        end
      end
    end
  end
end
