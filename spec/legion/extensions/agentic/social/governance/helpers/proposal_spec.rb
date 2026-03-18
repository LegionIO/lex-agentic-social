# frozen_string_literal: true

require 'legion/extensions/agentic/social/governance/helpers/layers'
require 'legion/extensions/agentic/social/governance/helpers/proposal'

RSpec.describe Legion::Extensions::Agentic::Social::Governance::Helpers::Proposal do
  subject(:proposal_store) { described_class.new }

  describe '#initialize' do
    it 'starts with an empty proposals hash' do
      expect(proposal_store.proposals).to eq({})
    end
  end

  describe '#create' do
    let(:created_id) do
      proposal_store.create(category: :policy_change, description: 'Enable new policy', proposer: 'agent-1')
    end

    it 'returns a UUID string' do
      expect(created_id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it 'stores the proposal under the returned ID' do
      expect(proposal_store.proposals[created_id]).not_to be_nil
    end

    it 'stores the correct category' do
      expect(proposal_store.proposals[created_id][:category]).to eq(:policy_change)
    end

    it 'stores the correct description' do
      expect(proposal_store.proposals[created_id][:description]).to eq('Enable new policy')
    end

    it 'stores the correct proposer' do
      expect(proposal_store.proposals[created_id][:proposer]).to eq('agent-1')
    end

    it 'defaults council_size to MIN_COUNCIL_SIZE' do
      expect(proposal_store.proposals[created_id][:council_size])
        .to eq(Legion::Extensions::Agentic::Social::Governance::Helpers::Layers::MIN_COUNCIL_SIZE)
    end

    it 'uses the provided council_size when specified' do
      id = proposal_store.create(category: :emergency, description: 'urgent', proposer: 'agent-x', council_size: 7)
      expect(proposal_store.proposals[id][:council_size]).to eq(7)
    end

    it 'initializes with status :open' do
      expect(proposal_store.proposals[created_id][:status]).to eq(:open)
    end

    it 'initializes votes_for as empty array' do
      expect(proposal_store.proposals[created_id][:votes_for]).to eq([])
    end

    it 'initializes votes_against as empty array' do
      expect(proposal_store.proposals[created_id][:votes_against]).to eq([])
    end

    it 'sets created_at to a Time object' do
      expect(proposal_store.proposals[created_id][:created_at]).to be_a(Time)
    end

    it 'sets resolved_at to nil initially' do
      expect(proposal_store.proposals[created_id][:resolved_at]).to be_nil
    end

    it 'generates unique IDs for separate calls' do
      id1 = proposal_store.create(category: :policy_change, description: 'a', proposer: 'x')
      id2 = proposal_store.create(category: :policy_change, description: 'b', proposer: 'y')
      expect(id1).not_to eq(id2)
    end
  end

  describe '#get' do
    it 'returns the proposal hash for a valid ID' do
      id = proposal_store.create(category: :policy_change, description: 'test', proposer: 'agent-1')
      result = proposal_store.get(id)
      expect(result[:proposal_id]).to eq(id)
    end

    it 'returns nil for an unknown ID' do
      expect(proposal_store.get('nonexistent-uuid')).to be_nil
    end
  end

  describe '#open_proposals' do
    it 'returns empty array when no proposals exist' do
      expect(proposal_store.open_proposals).to eq([])
    end

    it 'returns all open proposals' do
      proposal_store.create(category: :policy_change, description: 'first', proposer: 'a1')
      proposal_store.create(category: :emergency, description: 'second', proposer: 'a2')
      expect(proposal_store.open_proposals.size).to eq(2)
    end

    it 'excludes resolved proposals' do
      id = proposal_store.create(category: :policy_change, description: 'vote me', proposer: 'a1', council_size: 3)
      proposal_store.vote(id, voter: 'v1', approve: true)
      proposal_store.vote(id, voter: 'v2', approve: true)
      expect(proposal_store.open_proposals).to be_empty
    end
  end

  describe '#vote' do
    let(:proposal_id) do
      proposal_store.create(category: :policy_change, description: 'test', proposer: 'agent-1', council_size: 3)
    end

    it 'returns nil for an unknown proposal ID' do
      expect(proposal_store.vote('no-such-id', voter: 'v1', approve: true)).to be_nil
    end

    it 'returns :already_voted when the same voter votes twice' do
      proposal_store.vote(proposal_id, voter: 'v1', approve: true)
      result = proposal_store.vote(proposal_id, voter: 'v1', approve: false)
      expect(result).to eq(:already_voted)
    end

    it 'prevents double voting even when switching approve/reject' do
      proposal_store.vote(proposal_id, voter: 'v1', approve: false)
      result = proposal_store.vote(proposal_id, voter: 'v1', approve: true)
      expect(result).to eq(:already_voted)
    end

    it 'adds approve vote to votes_for' do
      proposal_store.vote(proposal_id, voter: 'v1', approve: true)
      expect(proposal_store.proposals[proposal_id][:votes_for]).to include('v1')
    end

    it 'adds reject vote to votes_against' do
      proposal_store.vote(proposal_id, voter: 'v1', approve: false)
      expect(proposal_store.proposals[proposal_id][:votes_against]).to include('v1')
    end

    it 'returns :pending when quorum is not yet met' do
      result = proposal_store.vote(proposal_id, voter: 'v1', approve: true)
      expect(result).to eq(:pending)
    end

    context 'when quorum for approval is met' do
      it 'returns :approved and sets status' do
        proposal_store.vote(proposal_id, voter: 'v1', approve: true)
        result = proposal_store.vote(proposal_id, voter: 'v2', approve: true)
        expect(result).to eq(:approved)
        expect(proposal_store.proposals[proposal_id][:status]).to eq(:approved)
      end

      it 'sets resolved_at on approval' do
        proposal_store.vote(proposal_id, voter: 'v1', approve: true)
        proposal_store.vote(proposal_id, voter: 'v2', approve: true)
        expect(proposal_store.proposals[proposal_id][:resolved_at]).to be_a(Time)
      end
    end

    context 'when quorum for rejection is met' do
      it 'returns :rejected when enough votes against' do
        proposal_store.vote(proposal_id, voter: 'v1', approve: false)
        result = proposal_store.vote(proposal_id, voter: 'v2', approve: false)
        expect(result).to eq(:rejected)
        expect(proposal_store.proposals[proposal_id][:status]).to eq(:rejected)
      end

      it 'sets resolved_at on rejection' do
        proposal_store.vote(proposal_id, voter: 'v1', approve: false)
        proposal_store.vote(proposal_id, voter: 'v2', approve: false)
        expect(proposal_store.proposals[proposal_id][:resolved_at]).to be_a(Time)
      end

      it 'returns :rejected when all council members voted and no quorum for approval' do
        proposal_store.vote(proposal_id, voter: 'v1', approve: true)
        proposal_store.vote(proposal_id, voter: 'v2', approve: false)
        result = proposal_store.vote(proposal_id, voter: 'v3', approve: false)
        expect(result).to eq(:rejected)
      end
    end

    it 'returns nil when voting on a resolved (approved) proposal' do
      proposal_store.vote(proposal_id, voter: 'v1', approve: true)
      proposal_store.vote(proposal_id, voter: 'v2', approve: true)
      result = proposal_store.vote(proposal_id, voter: 'v3', approve: true)
      expect(result).to be_nil
    end
  end
end
