# frozen_string_literal: true

require 'legion/extensions/agentic/social/conflict/client'

RSpec.describe Legion::Extensions::Agentic::Social::Conflict::Runners::Conflict do
  let(:client) { Legion::Extensions::Agentic::Social::Conflict::Client.new }

  describe '#register_conflict' do
    it 'creates a conflict with recommended posture' do
      result = client.register_conflict(parties: %w[agent human], severity: :high, description: 'disagreement')
      expect(result[:conflict_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:posture]).to eq(:persistent_engagement)
    end

    it 'recommends stubborn_presence for critical' do
      result = client.register_conflict(parties: %w[agent human], severity: :critical, description: 'safety issue')
      expect(result[:posture]).to eq(:stubborn_presence)
    end

    it 'rejects invalid severity' do
      result = client.register_conflict(parties: [], severity: :invalid, description: 'test')
      expect(result[:error]).to eq(:invalid_severity)
    end
  end

  describe '#add_exchange' do
    it 'records an exchange' do
      c = client.register_conflict(parties: %w[a b], severity: :medium, description: 'test')
      result = client.add_exchange(conflict_id: c[:conflict_id], speaker: 'a', message: 'I disagree')
      expect(result[:recorded]).to be true
    end
  end

  describe '#resolve_conflict' do
    it 'resolves a conflict' do
      c = client.register_conflict(parties: %w[a b], severity: :low, description: 'test')
      result = client.resolve_conflict(conflict_id: c[:conflict_id], outcome: :compromise)
      expect(result[:resolved]).to be true
    end
  end

  describe '#active_conflicts' do
    it 'lists active conflicts' do
      client.register_conflict(parties: %w[a b], severity: :low, description: 'test')
      result = client.active_conflicts
      expect(result[:count]).to eq(1)
    end
  end

  describe '#recommended_posture' do
    it 'returns posture for severity' do
      result = client.recommended_posture(severity: :critical)
      expect(result[:posture]).to eq(:stubborn_presence)
    end
  end

  describe '#check_stale_conflicts' do
    it 'returns zero stale when no conflicts exist' do
      result = client.check_stale_conflicts
      expect(result[:checked]).to eq(0)
      expect(result[:stale_count]).to eq(0)
      expect(result[:stale_ids]).to eq([])
    end

    it 'returns zero stale for recently created conflicts' do
      client.register_conflict(parties: %w[a b], severity: :low, description: 'fresh')
      result = client.check_stale_conflicts
      expect(result[:stale_count]).to eq(0)
    end

    it 'detects stale conflicts older than STALE_CONFLICT_TIMEOUT' do
      c = client.register_conflict(parties: %w[a b], severity: :medium, description: 'old')
      # Backdate the created_at timestamp
      conflict = client.instance_variable_get(:@conflict_log).conflicts[c[:conflict_id]]
      conflict[:created_at] = Time.now.utc - (Legion::Extensions::Agentic::Social::Conflict::Helpers::Severity::STALE_CONFLICT_TIMEOUT + 1)
      result = client.check_stale_conflicts
      expect(result[:stale_count]).to eq(1)
      expect(result[:stale_ids]).to include(c[:conflict_id])
    end

    it 'does not include resolved conflicts in stale check' do
      c = client.register_conflict(parties: %w[a b], severity: :low, description: 'resolved')
      conflict = client.instance_variable_get(:@conflict_log).conflicts[c[:conflict_id]]
      conflict[:created_at] = Time.now.utc - (Legion::Extensions::Agentic::Social::Conflict::Helpers::Severity::STALE_CONFLICT_TIMEOUT + 1)
      client.resolve_conflict(conflict_id: c[:conflict_id], outcome: :closed)
      result = client.check_stale_conflicts
      expect(result[:stale_count]).to eq(0)
    end

    context 'with LLM available' do
      let(:fake_chat) { double }
      let(:fake_analysis_response) do
        double(content: "RECOMMENDATION: escalate\nANALYSIS: The conflict has stalled and needs governance intervention.")
      end

      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: true))
        allow(Legion::LLM).to receive(:chat).and_return(fake_chat)
        allow(fake_chat).to receive(:with_instructions)
        allow(fake_chat).to receive(:ask).and_return(fake_analysis_response)
      end

      it 'includes LLM analysis in the stale system exchange message' do
        c = client.register_conflict(parties: %w[a b], severity: :high, description: 'ongoing issue')
        conflict = client.instance_variable_get(:@conflict_log).conflicts[c[:conflict_id]]
        conflict[:created_at] = Time.now.utc - (Legion::Extensions::Agentic::Social::Conflict::Helpers::Severity::STALE_CONFLICT_TIMEOUT + 1)

        client.check_stale_conflicts

        exchanges = client.instance_variable_get(:@conflict_log).conflicts[c[:conflict_id]][:exchanges]
        expect(exchanges).not_to be_empty
        system_msg = exchanges.find { |e| e[:speaker] == :system }
        expect(system_msg).not_to be_nil
        expect(system_msg[:message]).to include('governance intervention')
      end
    end
  end

  describe '#resolve_conflict with LLM' do
    let(:fake_chat) { double }
    let(:fake_resolution_response) do
      double(content: <<~TEXT)
        OUTCOME: resolved
        NOTES: Both parties reached a compromise after reviewing the evidence. Next steps include documenting the outcome and monitoring for recurrence.
      TEXT
    end

    before do
      stub_const('Legion::LLM', double(respond_to?: true, started?: true))
      allow(Legion::LLM).to receive(:chat).and_return(fake_chat)
      allow(fake_chat).to receive(:with_instructions)
      allow(fake_chat).to receive(:ask).and_return(fake_resolution_response)
    end

    it 'uses LLM-generated notes when no resolution_notes provided' do
      c = client.register_conflict(parties: %w[a b], severity: :medium, description: 'test conflict')
      client.resolve_conflict(conflict_id: c[:conflict_id], outcome: :compromise)

      conflict = client.instance_variable_get(:@conflict_log).conflicts[c[:conflict_id]]
      expect(conflict[:resolution_notes]).to include('compromise')
    end

    it 'preserves caller-provided resolution_notes over LLM' do
      c = client.register_conflict(parties: %w[a b], severity: :medium, description: 'test conflict')
      client.resolve_conflict(conflict_id: c[:conflict_id], outcome: :compromise, resolution_notes: 'manual notes')

      conflict = client.instance_variable_get(:@conflict_log).conflicts[c[:conflict_id]]
      expect(conflict[:resolution_notes]).to eq('manual notes')
    end
  end
end
