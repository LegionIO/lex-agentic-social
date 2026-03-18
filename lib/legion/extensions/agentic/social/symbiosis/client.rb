# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Symbiosis
          class Client
            include Runners::CognitiveSymbiosis

            def initialize(**)
              @default_engine = Helpers::SymbiosisEngine.new
            end

            private

            attr_reader :default_engine
          end
        end
      end
    end
  end
end
