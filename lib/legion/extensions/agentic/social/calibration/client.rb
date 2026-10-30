# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Calibration
          class Client
            include Runners::Calibration

            def initialize(calibration_store: nil, calibration_registry: nil, **)
              @calibration_store = calibration_store || Legion::Extensions::Agentic::Social::Calibration::Helpers::CalibrationStore.new
              @calibration_registry = calibration_registry || Legion::Extensions::Agentic::Social::Calibration::Helpers::CalibrationRegistry.new
            end
          end
        end
      end
    end
  end
end
