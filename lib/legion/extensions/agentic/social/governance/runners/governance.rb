# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Governance
          module Runners
            module Governance
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def create_proposal(category:, description:, proposer:, council_size: nil, **)
                return { error: :invalid_category, valid: Helpers::Layers::PROPOSAL_CATEGORIES } unless Helpers::Layers.valid_category?(category)

                size = council_size || Helpers::Layers::MIN_COUNCIL_SIZE
                id = proposal_store.create(category: category, description: description,
                                           proposer: proposer, council_size: size)
                Legion::Logging.info "[governance] proposal created: id=#{id[0..7]} category=#{category} proposer=#{proposer} council=#{size}"
                { proposal_id: id, category: category, status: :open }
              end

              def vote_on_proposal(proposal_id:, voter:, approve:, **)
                result = proposal_store.vote(proposal_id, voter: voter, approve: approve)
                case result
                when nil
                  Legion::Logging.debug "[governance] vote failed: proposal=#{proposal_id[0..7]} not found or closed"
                  { error: :not_found_or_closed }
                when :already_voted
                  Legion::Logging.debug "[governance] vote failed: proposal=#{proposal_id[0..7]} voter=#{voter} already voted"
                  { error: :already_voted }
                else
                  Legion::Logging.info "[governance] vote: proposal=#{proposal_id[0..7]} voter=#{voter} approve=#{approve} resolution=#{result}"
                  { voted: true, resolution: result }
                end
              end

              def get_proposal(proposal_id:, **)
                prop = proposal_store.get(proposal_id)
                Legion::Logging.debug "[governance] get: proposal=#{proposal_id[0..7]} found=#{!prop.nil?}"
                prop ? { found: true, proposal: prop } : { found: false }
              end

              def open_proposals(**)
                props = proposal_store.open_proposals
                Legion::Logging.debug "[governance] open proposals: count=#{props.size}"
                { proposals: props, count: props.size }
              end

              def timeout_proposals(**)
                open  = proposal_store.open_proposals
                timed = open.select { |p| Time.now.utc - p[:created_at] > Helpers::Layers::VOTE_TIMEOUT }
                timed.each { |p| proposal_store.resolve_timed_out(p[:proposal_id]) }
                timed_ids = timed.map { |p| p[:proposal_id] }
                Legion::Logging.debug "[governance] vote timeout sweep: open=#{open.size} timed_out=#{timed.size}"
                { checked: open.size, timed_out: timed.size, timed_out_ids: timed_ids }
              end

              def validate_action(layer:, action: nil, _context: {}, **) # rubocop:disable Lint/UnusedMethodArgument
                return { error: :invalid_layer } unless Helpers::Layers.valid_layer?(layer)

                result = case layer
                         when :agent_validation
                           { allowed: true, layer: layer, reason: :self_validated }
                         when :anomaly_detection
                           { allowed: true, layer: layer, reason: :no_anomaly }
                         when :human_deliberation
                           { allowed: false, layer: layer, reason: :requires_human_approval }
                         when :transparency
                           { allowed: true, layer: layer, reason: :logged, audit_required: true }
                         end
                Legion::Logging.debug "[governance] validate: layer=#{layer} allowed=#{result[:allowed]} reason=#{result[:reason]}"
                result
              end

              private

              def proposal_store
                @proposal_store ||= Helpers::Proposal.new
              end
            end
          end
        end
      end
    end
  end
end
