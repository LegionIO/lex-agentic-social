# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MoralReasoning::Runners::MoralReasoning do
  let(:client) { Legion::Extensions::Agentic::Social::MoralReasoning::Client.new }
  let(:enhancer) { Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::LlmEnhancer }

  let(:options) do
    [
      { id: 'opt_a', description: 'Care approach', foundations: %i[care fairness] },
      { id: 'opt_b', description: 'Rule approach', foundations: %i[authority loyalty] }
    ]
  end

  describe '#evaluate_moral_action' do
    it 'returns success with a score' do
      result = client.evaluate_moral_action(
        action:               'help_stranger',
        affected_foundations: %i[care fairness]
      )
      expect(result[:success]).to be true
      expect(result[:score]).to be_a(Float)
    end

    it 'accepts a domain parameter' do
      result = client.evaluate_moral_action(
        action:               'whistleblow',
        affected_foundations: %i[fairness],
        domain:               :workplace
      )
      expect(result[:domain]).to eq(:workplace)
    end

    context 'when LLM is available' do
      let(:llm_result) do
        {
          reasoning:          'LLM ethical analysis of this action.',
          foundation_impacts: { care: 0.2, fairness: 0.1, loyalty: -0.05,
                                authority: 0.0, sanctity: 0.1, liberty: 0.05 }
        }
      end

      before do
        allow(enhancer).to receive(:available?).and_return(true)
        allow(enhancer).to receive(:evaluate_action).and_return(llm_result)
      end

      it 'returns source: :llm' do
        result = client.evaluate_moral_action(
          action:               'help_stranger',
          affected_foundations: %i[care fairness]
        )
        expect(result[:source]).to eq(:llm)
      end

      it 'includes LLM reasoning' do
        result = client.evaluate_moral_action(
          action:               'help_stranger',
          affected_foundations: %i[care fairness]
        )
        expect(result[:reasoning]).to eq('LLM ethical analysis of this action.')
      end

      it 'includes foundation_impacts from LLM' do
        result = client.evaluate_moral_action(
          action:               'help_stranger',
          affected_foundations: %i[care fairness]
        )
        expect(result[:foundation_impacts]).to eq(llm_result[:foundation_impacts])
      end
    end

    context 'when LLM is unavailable' do
      before do
        allow(enhancer).to receive(:available?).and_return(false)
      end

      it 'returns source: :mechanical' do
        result = client.evaluate_moral_action(
          action:               'help_stranger',
          affected_foundations: %i[care fairness]
        )
        expect(result[:source]).to eq(:mechanical)
      end

      it 'still returns success: true' do
        result = client.evaluate_moral_action(
          action:               'help_stranger',
          affected_foundations: %i[care fairness]
        )
        expect(result[:success]).to be true
      end
    end

    context 'when LLM returns nil' do
      before do
        allow(enhancer).to receive(:available?).and_return(true)
        allow(enhancer).to receive(:evaluate_action).and_return(nil)
      end

      it 'falls back to mechanical and returns source: :mechanical' do
        result = client.evaluate_moral_action(
          action:               'help_stranger',
          affected_foundations: %i[care fairness]
        )
        expect(result[:source]).to eq(:mechanical)
      end
    end
  end

  describe '#pose_moral_dilemma' do
    it 'creates a dilemma' do
      result = client.pose_moral_dilemma(
        description: 'Test dilemma',
        options:     options
      )
      expect(result[:success]).to be true
      expect(result[:dilemma][:description]).to eq('Test dilemma')
    end
  end

  describe '#resolve_moral_dilemma' do
    let(:dilemma_id) do
      client.pose_moral_dilemma(description: 'Resolve test', options: options)[:dilemma][:id]
    end

    it 'resolves a dilemma' do
      result = client.resolve_moral_dilemma(
        dilemma_id: dilemma_id,
        option_id:  'opt_a',
        reasoning:  'Greatest good',
        framework:  :utilitarian
      )
      expect(result[:success]).to be true
      expect(result[:dilemma][:resolved]).to be true
    end

    it 'returns failure for unknown dilemma' do
      result = client.resolve_moral_dilemma(
        dilemma_id: 'bad_id',
        option_id:  'opt_a',
        reasoning:  'N/A',
        framework:  :utilitarian
      )
      expect(result[:success]).to be false
    end

    context 'when LLM is available' do
      let(:llm_result) do
        {
          chosen_option: 'opt_a',
          confidence:    0.88,
          reasoning:     'Utilitarian calculus favors this option for the greatest collective benefit.'
        }
      end

      before do
        allow(enhancer).to receive(:available?).and_return(true)
        allow(enhancer).to receive(:resolve_dilemma).and_return(llm_result)
      end

      it 'returns source: :llm' do
        result = client.resolve_moral_dilemma(
          dilemma_id: dilemma_id,
          option_id:  'opt_a',
          reasoning:  'manual reasoning',
          framework:  :utilitarian
        )
        expect(result[:source]).to eq(:llm)
      end

      it 'includes llm_chosen and llm_confidence' do
        result = client.resolve_moral_dilemma(
          dilemma_id: dilemma_id,
          option_id:  'opt_a',
          reasoning:  'manual reasoning',
          framework:  :utilitarian
        )
        expect(result[:llm_chosen]).to eq('opt_a')
        expect(result[:llm_confidence]).to eq(0.88)
      end

      it 'resolves successfully using LLM reasoning' do
        result = client.resolve_moral_dilemma(
          dilemma_id: dilemma_id,
          option_id:  'opt_a',
          reasoning:  'manual reasoning',
          framework:  :utilitarian
        )
        expect(result[:success]).to be true
      end
    end

    context 'when LLM is unavailable' do
      before do
        allow(enhancer).to receive(:available?).and_return(false)
      end

      it 'resolves mechanically without source key from LLM' do
        result = client.resolve_moral_dilemma(
          dilemma_id: dilemma_id,
          option_id:  'opt_a',
          reasoning:  'manual reasoning',
          framework:  :utilitarian
        )
        expect(result[:success]).to be true
        expect(result[:source]).to be_nil
      end
    end
  end

  describe '#apply_ethical_framework' do
    let(:dilemma_id) do
      client.pose_moral_dilemma(description: 'Framework test', options: options)[:dilemma][:id]
    end

    it 'applies a framework and returns rankings' do
      result = client.apply_ethical_framework(dilemma_id: dilemma_id, framework: :care)
      expect(result[:success]).to be true
      expect(result[:rankings]).to be_an(Array)
    end
  end

  describe '#add_moral_principle' do
    it 'adds a principle' do
      result = client.add_moral_principle(
        name:        'Non-maleficence',
        description: 'Do not harm',
        foundation:  :care
      )
      expect(result[:success]).to be true
    end
  end

  describe '#check_moral_development' do
    it 'returns success with current stage' do
      result = client.check_moral_development
      expect(result[:success]).to be true
      expect(result[:stage]).to be_a(Symbol)
    end
  end

  describe '#moral_foundation_profile' do
    it 'returns all foundations' do
      result = client.moral_foundation_profile
      expect(result[:success]).to be true
      expect(result[:foundations].keys).to match_array(
        Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::MORAL_FOUNDATIONS
      )
    end
  end

  describe '#moral_stage_info' do
    it 'returns stage, level, and description' do
      result = client.moral_stage_info
      expect(result[:success]).to be true
      expect(result).to include(:stage, :level, :description)
    end
  end

  describe '#update_moral_reasoning' do
    it 'decays foundations and returns profile' do
      result = client.update_moral_reasoning
      expect(result[:success]).to be true
      expect(result[:foundations]).to be_a(Hash)
    end
  end

  describe '#moral_reasoning_stats' do
    it 'returns stats including stage and counts' do
      result = client.moral_reasoning_stats
      expect(result[:success]).to be true
      expect(result).to include(:stage, :total_dilemmas, :resolved_dilemmas)
    end
  end
end
