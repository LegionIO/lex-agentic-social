# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module Governance
          module Helpers
            class Proposal
              attr_reader :proposals

              def initialize
                @proposals = {}
              end

              def create(category:, description:, proposer:, council_size: Layers::MIN_COUNCIL_SIZE)
                id = SecureRandom.uuid
                @proposals[id] = {
                  proposal_id:   id,
                  category:      category,
                  description:   description,
                  proposer:      proposer,
                  council_size:  council_size,
                  votes_for:     [],
                  votes_against: [],
                  status:        :open,
                  created_at:    Time.now.utc,
                  resolved_at:   nil
                }
                id
              end

              def vote(proposal_id, voter:, approve:)
                prop = @proposals[proposal_id]
                return nil unless prop && prop[:status] == :open

                # Prevent double-voting
                all_voters = prop[:votes_for] + prop[:votes_against]
                return :already_voted if all_voters.include?(voter)

                if approve
                  prop[:votes_for] << voter
                else
                  prop[:votes_against] << voter
                end

                check_resolution(proposal_id)
              end

              def get(proposal_id)
                @proposals[proposal_id]
              end

              def open_proposals
                @proposals.values.select { |p| p[:status] == :open }
              end

              def resolve_timed_out(proposal_id)
                prop = @proposals[proposal_id]
                return nil unless prop && prop[:status] == :open

                prop[:status]      = :timed_out
                prop[:resolved_at] = Time.now.utc
                prop
              end

              private

              def check_resolution(proposal_id)
                prop = @proposals[proposal_id]
                total_votes = prop[:votes_for].size + prop[:votes_against].size

                if Layers.quorum_met?(prop[:votes_for].size, prop[:council_size])
                  prop[:status] = :approved
                  prop[:resolved_at] = Time.now.utc
                  :approved
                elsif Layers.quorum_met?(prop[:votes_against].size, prop[:council_size]) ||
                      total_votes >= prop[:council_size]
                  prop[:status] = :rejected
                  prop[:resolved_at] = Time.now.utc
                  :rejected
                else
                  :pending
                end
              end
            end
          end
        end
      end
    end
  end
end
