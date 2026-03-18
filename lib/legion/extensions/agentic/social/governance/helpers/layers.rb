# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Governance
          module Helpers
            module Layers
              # Four governance layers (spec: governance-protocol-spec.md)
              GOVERNANCE_LAYERS = %i[agent_validation anomaly_detection human_deliberation transparency].freeze

              # Council quorum requirements
              MIN_COUNCIL_SIZE    = 3
              QUORUM_FRACTION     = 0.66
              VOTE_TIMEOUT        = 86_400 # 24 hours
              PROPOSAL_CATEGORIES = %i[policy_change resource_allocation access_control emergency protocol_update].freeze

              module_function

              def valid_layer?(layer)
                GOVERNANCE_LAYERS.include?(layer)
              end

              def valid_category?(category)
                PROPOSAL_CATEGORIES.include?(category)
              end

              def quorum_met?(votes, council_size)
                return false if council_size < MIN_COUNCIL_SIZE

                votes >= (council_size * QUORUM_FRACTION).ceil
              end
            end
          end
        end
      end
    end
  end
end
