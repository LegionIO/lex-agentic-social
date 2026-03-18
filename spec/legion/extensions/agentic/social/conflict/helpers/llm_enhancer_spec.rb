# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Conflict::Helpers::LlmEnhancer do
  describe '.available?' do
    context 'when Legion::LLM is not defined' do
      it 'returns a falsy value' do
        # Legion::LLM is not defined in the test environment
        expect(described_class.available?).to be_falsy
      end
    end

    context 'when Legion::LLM is defined but not started' do
      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: false))
      end

      it 'returns false' do
        expect(described_class.available?).to be false
      end
    end

    context 'when Legion::LLM is started' do
      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: true))
      end

      it 'returns true' do
        expect(described_class.available?).to be true
      end
    end

    context 'when an error is raised' do
      before do
        stub_const('Legion::LLM', double)
        allow(Legion::LLM).to receive(:respond_to?).and_raise(StandardError)
      end

      it 'returns false' do
        expect(described_class.available?).to be false
      end
    end
  end

  describe '.suggest_resolution' do
    let(:fake_response) do
      double(content: <<~TEXT)
        OUTCOME: resolved
        NOTES: Both parties agreed to table the discussion for 48 hours. The agent will document its reasoning and the human partner will review before resuming.
      TEXT
    end
    let(:fake_chat) { double }

    before do
      stub_const('Legion::LLM', double)
      allow(Legion::LLM).to receive(:chat).and_return(fake_chat)
      allow(fake_chat).to receive(:with_instructions)
      allow(fake_chat).to receive(:ask).and_return(fake_response)
    end

    it 'returns resolution_notes and suggested_outcome' do
      result = described_class.suggest_resolution(
        description: 'Agent and human disagree on approach',
        severity:    :high,
        exchanges:   [{ speaker: :agent, message: 'I think we should proceed' },
                      { speaker: :human, message: 'I disagree with that approach' }]
      )
      expect(result).to be_a(Hash)
      expect(result[:resolution_notes]).to be_a(String)
      expect(result[:resolution_notes]).not_to be_empty
      expect(result[:suggested_outcome]).to eq(:resolved)
    end

    it 'handles deferred outcome' do
      allow(fake_chat).to receive(:ask).and_return(
        double(content: "OUTCOME: deferred\nNOTES: Issue requires more context before resolution.")
      )
      result = described_class.suggest_resolution(
        description: 'Ongoing concern', severity: :medium, exchanges: []
      )
      expect(result[:suggested_outcome]).to eq(:deferred)
    end

    it 'handles escalated outcome' do
      allow(fake_chat).to receive(:ask).and_return(
        double(content: "OUTCOME: escalated\nNOTES: Critical disagreement requires governance council review.")
      )
      result = described_class.suggest_resolution(
        description: 'Safety concern', severity: :critical, exchanges: []
      )
      expect(result[:suggested_outcome]).to eq(:escalated)
    end

    context 'when LLM returns nil content' do
      before { allow(fake_chat).to receive(:ask).and_return(double(content: nil)) }

      it 'returns nil' do
        result = described_class.suggest_resolution(
          description: 'test', severity: :low, exchanges: []
        )
        expect(result).to be_nil
      end
    end

    context 'when LLM raises an error' do
      before { allow(fake_chat).to receive(:ask).and_raise(StandardError, 'LLM unavailable') }

      it 'returns nil and logs a warning' do
        expect(Legion::Logging).to receive(:warn).with(/suggest_resolution failed/)
        result = described_class.suggest_resolution(
          description: 'test', severity: :low, exchanges: []
        )
        expect(result).to be_nil
      end
    end
  end

  describe '.analyze_stale_conflict' do
    let(:fake_response) do
      double(content: <<~TEXT)
        RECOMMENDATION: escalate
        ANALYSIS: This conflict has persisted for 36 hours without progress. The critical severity and lack of exchanges suggests governance council intervention.
      TEXT
    end
    let(:fake_chat) { double }

    before do
      stub_const('Legion::LLM', double)
      allow(Legion::LLM).to receive(:chat).and_return(fake_chat)
      allow(fake_chat).to receive(:with_instructions)
      allow(fake_chat).to receive(:ask).and_return(fake_response)
    end

    it 'returns analysis and recommendation' do
      result = described_class.analyze_stale_conflict(
        description:    'Critical safety disagreement',
        severity:       :critical,
        age_hours:      36.5,
        exchange_count: 2
      )
      expect(result).to be_a(Hash)
      expect(result[:analysis]).to be_a(String)
      expect(result[:analysis]).not_to be_empty
      expect(result[:recommendation]).to eq(:escalate)
    end

    it 'handles retry recommendation' do
      allow(fake_chat).to receive(:ask).and_return(
        double(content: "RECOMMENDATION: retry\nANALYSIS: The conflict may be resolvable with a fresh attempt after cooling off.")
      )
      result = described_class.analyze_stale_conflict(
        description: 'Minor dispute', severity: :low, age_hours: 25.0, exchange_count: 1
      )
      expect(result[:recommendation]).to eq(:retry)
    end

    it 'handles close recommendation' do
      allow(fake_chat).to receive(:ask).and_return(
        double(content: "RECOMMENDATION: close\nANALYSIS: The issue is no longer relevant and can be safely closed.")
      )
      result = described_class.analyze_stale_conflict(
        description: 'Old dispute', severity: :low, age_hours: 48.0, exchange_count: 0
      )
      expect(result[:recommendation]).to eq(:close)
    end

    context 'when LLM returns nil content' do
      before { allow(fake_chat).to receive(:ask).and_return(double(content: nil)) }

      it 'returns nil' do
        result = described_class.analyze_stale_conflict(
          description: 'test', severity: :low, age_hours: 25.0, exchange_count: 0
        )
        expect(result).to be_nil
      end
    end

    context 'when LLM raises an error' do
      before { allow(fake_chat).to receive(:ask).and_raise(StandardError, 'connection refused') }

      it 'returns nil and logs a warning' do
        expect(Legion::Logging).to receive(:warn).with(/analyze_stale_conflict failed/)
        result = described_class.analyze_stale_conflict(
          description: 'test', severity: :medium, age_hours: 30.0, exchange_count: 3
        )
        expect(result).to be_nil
      end
    end
  end
end
