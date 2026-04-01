# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Calibration
          class Client
            include Runners::Calibration

            def initialize(**)
              @calibration_store = Helpers::CalibrationStore.new
            end

            private

            attr_reader :calibration_store
          end
        end
      end
    end
  end
end
