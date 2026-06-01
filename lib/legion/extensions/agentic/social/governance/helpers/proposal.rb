# frozen_string_literal: true

require 'time'
require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Social
        module Governance
          module Helpers
            class Proposal
              PROPOSAL_TAG_BASE = %w[governance proposal].freeze

              attr_reader :proposals

              def initialize
                @proposals = {}
                load_from_apollo
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
                save_proposal(id)
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

                save_proposal(proposal_id)
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
                save_proposal(proposal_id)
                prop
              end

              def load_from_apollo
                return false unless defined?(Legion::Apollo::Local) && Legion::Apollo::Local.started?

                result = Legion::Apollo::Local.query_by_tags(tags: PROPOSAL_TAG_BASE, limit: 1000)
                return false unless result[:success] && result[:results].is_a?(Array)

                result[:results].each do |entry|
                  data = ::JSON.parse(entry[:content], symbolize_names: true)
                  pid = data[:proposal_id]
                  next unless pid

                  # Convert string timestamps back to Time objects
                  data[:created_at] = Time.parse(data[:created_at].to_s) if data[:created_at]
                  data[:resolved_at] = data[:resolved_at] ? Time.parse(data[:resolved_at].to_s) : nil

                  # Ensure status is a symbol
                  data[:status] = data[:status].to_sym if data[:status].is_a?(String)

                  @proposals[pid] = data
                rescue StandardError => e
                  Legion::Logging.warn "[governance] load_from_apollo parse error: #{e.message}"
                end

                @proposals.any?
              rescue StandardError => e
                Legion::Logging.warn "[governance] load_from_apollo failed: #{e.message}"
                false
              end

              private

              def save_proposal(proposal_id)
                return unless defined?(Legion::Apollo::Local) && Legion::Apollo::Local.started?

                prop = @proposals[proposal_id]
                return unless prop

                # Convert to JSON-safe format
                serializable = prop.dup
                serializable[:created_at] = prop[:created_at].is_a?(Time) ? prop[:created_at].iso8601 : prop[:created_at]
                serializable[:resolved_at] = prop[:resolved_at]&.iso8601

                content = Legion::JSON.dump(serializable)
                tags = PROPOSAL_TAG_BASE + ["category:#{prop[:category]}", "status:#{prop[:status]}"]

                Legion::Apollo::Local.upsert(
                  content:               content,
                  tags:                  tags,
                  access_scope:          'private',
                  identity_principal_id: nil
                )
              rescue StandardError => e
                Legion::Logging.warn "[governance] save_proposal failed: #{e.message}"
              end

              def check_resolution(proposal_id)
                prop = @proposals[proposal_id]
                total_votes = prop[:votes_for].size + prop[:votes_against].size

                if Layers.quorum_met?(prop[:votes_for].size, prop[:council_size])
                  prop[:status] = :approved
                  prop[:resolved_at] = Time.now.utc
                  save_proposal(proposal_id)
                  :approved
                elsif Layers.quorum_met?(prop[:votes_against].size, prop[:council_size]) ||
                      total_votes >= prop[:council_size]
                  prop[:status] = :rejected
                  prop[:resolved_at] = Time.now.utc
                  save_proposal(proposal_id)
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
