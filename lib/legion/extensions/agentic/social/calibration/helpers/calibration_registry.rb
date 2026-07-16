# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Calibration
          module Helpers
            class CalibrationRegistry
              def initialize
                @stores = {}
                @mutex  = Mutex.new
              end

              def for(identity:)
                @mutex.synchronize { @stores[identity.to_s] ||= CalibrationStore.new }
              end

              def erase_partner!(identity:)
                @mutex.synchronize { @stores.delete(identity.to_s) }
                true
              end

              def known_identities
                @mutex.synchronize { @stores.keys.dup }
              end

              def to_apollo_entries_for(identity:)
                store = @mutex.synchronize { @stores[identity.to_s] }
                return [] unless store

                store.to_apollo_entries
              end
            end
          end
        end
      end
    end
  end
end
