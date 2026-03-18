# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::LlmEnhancer do
  subject(:enhancer) { described_class }

  let(:foundations) { { care: 0.5, fairness: 0.6, loyalty: 0.4, authority: 0.5, sanctity: 0.4, liberty: 0.5 } }

  let(:options) do
    [
      { id: 'opt_a', description: 'Prioritize care', foundations: %i[care fairness] },
      { id: 'opt_b', description: 'Follow rules',    foundations: %i[authority loyalty] }
    ]
  end

  describe '.available?' do
    context 'when Legion::LLM is not defined' do
      it 'returns false' do
        expect(enhancer.available?).to be false
      end
    end

    context 'when Legion::LLM is defined but not started' do
      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: false))
      end

      it 'returns false' do
        expect(enhancer.available?).to be false
      end
    end

    context 'when Legion::LLM is started' do
      before do
        stub_const('Legion::LLM', double(respond_to?: true, started?: true))
      end

      it 'returns true' do
        expect(enhancer.available?).to be true
      end
    end

    context 'when Legion::LLM raises an error' do
      before do
        stub_const('Legion::LLM', double)
        allow(Legion::LLM).to receive(:respond_to?).and_raise(StandardError, 'boom')
      end

      it 'returns false' do
        expect(enhancer.available?).to be false
      end
    end
  end

  describe '.evaluate_action' do
    let(:mock_response) do
      content = <<~TEXT
        REASONING: This action demonstrates care for others and promotes fairness. It strengthens the foundational values of justice and compassion.
        IMPACT: care=0.3 | fairness=0.2 | loyalty=-0.1 | authority=0.0 | sanctity=0.1 | liberty=0.15
      TEXT
      double('response', content: content)
    end

    before do
      stub_const('Legion::LLM', double)
      chat = double('chat')
      allow(Legion::LLM).to receive(:chat).and_return(chat)
      allow(chat).to receive(:with_instructions)
      allow(chat).to receive(:ask).and_return(mock_response)
    end

    it 'returns reasoning and foundation_impacts' do
      result = enhancer.evaluate_action(
        action:      :help_stranger,
        description: 'Helping someone in need',
        foundations: foundations
      )
      expect(result).to be_a(Hash)
      expect(result[:reasoning]).to be_a(String)
      expect(result[:reasoning]).not_to be_empty
      expect(result[:foundation_impacts]).to be_a(Hash)
    end

    it 'parses all foundation impacts' do
      result = enhancer.evaluate_action(
        action:      :help_stranger,
        description: 'Helping someone in need',
        foundations: foundations
      )
      expect(result[:foundation_impacts].keys).to include(:care, :fairness, :loyalty)
    end

    it 'clamps foundation impact values to -1.0..1.0' do
      result = enhancer.evaluate_action(
        action:      :help_stranger,
        description: 'Helping someone in need',
        foundations: foundations
      )
      result[:foundation_impacts].each_value do |val|
        expect(val).to be_between(-1.0, 1.0)
      end
    end

    context 'when LLM raises an error' do
      before do
        chat = double('chat')
        allow(Legion::LLM).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_instructions)
        allow(chat).to receive(:ask).and_raise(StandardError, 'API unavailable')
      end

      it 'returns nil' do
        result = enhancer.evaluate_action(
          action:      :help_stranger,
          description: 'test',
          foundations: foundations
        )
        expect(result).to be_nil
      end
    end

    context 'when response has no content' do
      before do
        chat = double('chat')
        allow(Legion::LLM).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_instructions)
        allow(chat).to receive(:ask).and_return(double('response', content: nil))
      end

      it 'returns nil' do
        result = enhancer.evaluate_action(
          action:      :test,
          description: 'test',
          foundations: foundations
        )
        expect(result).to be_nil
      end
    end

    context 'when response has malformed IMPACT line' do
      before do
        bad_response = double('response', content: 'REASONING: some text only, no IMPACT line')
        chat = double('chat')
        allow(Legion::LLM).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_instructions)
        allow(chat).to receive(:ask).and_return(bad_response)
      end

      it 'returns nil' do
        result = enhancer.evaluate_action(action: :test, description: 'test', foundations: foundations)
        expect(result).to be_nil
      end
    end
  end

  describe '.resolve_dilemma' do
    let(:mock_response) do
      content = <<~TEXT
        CHOSEN: opt_a
        CONFIDENCE: 0.82
        REASONING: From a care ethics perspective, prioritizing the wellbeing of those directly affected aligns with the core principle of nurturing relationships and responding to vulnerability.
      TEXT
      double('response', content: content)
    end

    before do
      stub_const('Legion::LLM', double)
      chat = double('chat')
      allow(Legion::LLM).to receive(:chat).and_return(chat)
      allow(chat).to receive(:with_instructions)
      allow(chat).to receive(:ask).and_return(mock_response)
    end

    it 'returns chosen_option, confidence, and reasoning' do
      result = enhancer.resolve_dilemma(
        dilemma_description: 'Should the agent reveal sensitive information?',
        options:             options,
        framework:           :care
      )
      expect(result).to be_a(Hash)
      expect(result[:chosen_option]).to eq('opt_a')
      expect(result[:confidence]).to be_a(Float)
      expect(result[:reasoning]).to be_a(String)
      expect(result[:reasoning]).not_to be_empty
    end

    it 'clamps confidence to 0.0..1.0' do
      result = enhancer.resolve_dilemma(
        dilemma_description: 'Test',
        options:             options,
        framework:           :utilitarian
      )
      expect(result[:confidence]).to be_between(0.0, 1.0)
    end

    context 'when LLM raises an error' do
      before do
        chat = double('chat')
        allow(Legion::LLM).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_instructions)
        allow(chat).to receive(:ask).and_raise(StandardError, 'timeout')
      end

      it 'returns nil' do
        result = enhancer.resolve_dilemma(
          dilemma_description: 'test',
          options:             options,
          framework:           :utilitarian
        )
        expect(result).to be_nil
      end
    end

    context 'when response is malformed' do
      before do
        bad_response = double('response', content: 'This is just some text without any format markers.')
        chat = double('chat')
        allow(Legion::LLM).to receive(:chat).and_return(chat)
        allow(chat).to receive(:with_instructions)
        allow(chat).to receive(:ask).and_return(bad_response)
      end

      it 'returns nil' do
        result = enhancer.resolve_dilemma(
          dilemma_description: 'test',
          options:             options,
          framework:           :deontological
        )
        expect(result).to be_nil
      end
    end
  end
end
