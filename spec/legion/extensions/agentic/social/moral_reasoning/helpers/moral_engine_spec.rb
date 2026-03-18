# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::MoralEngine do
  subject(:engine) { described_class.new }

  let(:options) do
    [
      { id: 'opt_a', description: 'Help the many', foundations: %i[care fairness] },
      { id: 'opt_b', description: 'Follow the rule', foundations: %i[authority loyalty] }
    ]
  end

  describe '#initialize' do
    it 'starts at :social_contract stage' do
      expect(engine.stage).to eq(:social_contract)
    end

    it 'initializes all moral foundations' do
      profile = engine.foundation_profile
      Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::MORAL_FOUNDATIONS.each do |f|
        expect(profile).to have_key(f)
      end
    end

    it 'starts with empty dilemmas and principles' do
      expect(engine.dilemmas).to be_empty
      expect(engine.principles).to be_empty
    end
  end

  describe '#evaluate_action' do
    it 'returns a score for an action' do
      result = engine.evaluate_action(action: 'help_stranger', affected_foundations: %i[care fairness])
      expect(result[:score]).to be_a(Float)
      expect(result[:score]).to be >= 0.0
    end

    it 'returns 0.0 for empty foundations' do
      result = engine.evaluate_action(action: 'noop', affected_foundations: [])
      expect(result[:score]).to eq(0.0)
    end

    it 'includes action and domain in result' do
      result = engine.evaluate_action(action: 'report', affected_foundations: %i[loyalty], domain: :workplace)
      expect(result[:action]).to eq('report')
      expect(result[:domain]).to eq(:workplace)
    end
  end

  describe '#pose_dilemma' do
    it 'creates a dilemma and returns success' do
      result = engine.pose_dilemma(description: 'Trolley problem', options: options)
      expect(result[:success]).to be true
      expect(result[:dilemma][:description]).to eq('Trolley problem')
    end

    it 'assigns a unique id' do
      r1 = engine.pose_dilemma(description: 'A', options: options)
      r2 = engine.pose_dilemma(description: 'B', options: options)
      expect(r1[:dilemma][:id]).not_to eq(r2[:dilemma][:id])
    end

    it 'stores the dilemma in @dilemmas' do
      engine.pose_dilemma(description: 'Test', options: options)
      expect(engine.dilemmas).not_to be_empty
    end

    it 'returns failure when max dilemmas reached' do
      Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::MAX_DILEMMAS.times do |i|
        engine.pose_dilemma(description: "Dilemma #{i}", options: options)
      end
      result = engine.pose_dilemma(description: 'One more', options: options)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:max_dilemmas_reached)
    end
  end

  describe '#resolve_dilemma' do
    let(:dilemma_id) do
      engine.pose_dilemma(description: 'Test dilemma', options: options)[:dilemma][:id]
    end

    it 'resolves an existing dilemma' do
      result = engine.resolve_dilemma(
        dilemma_id: dilemma_id, option_id: 'opt_a',
        reasoning: 'Most good', framework: :utilitarian
      )
      expect(result[:success]).to be true
      expect(result[:dilemma][:resolved]).to be true
    end

    it 'returns failure for unknown dilemma_id' do
      result = engine.resolve_dilemma(
        dilemma_id: 'nonexistent', option_id: 'opt_a',
        reasoning: 'N/A', framework: :utilitarian
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'returns failure for invalid option_id' do
      result = engine.resolve_dilemma(
        dilemma_id: dilemma_id, option_id: 'bad_opt',
        reasoning: 'N/A', framework: :utilitarian
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_option)
    end

    it 'returns failure if already resolved' do
      engine.resolve_dilemma(
        dilemma_id: dilemma_id, option_id: 'opt_a',
        reasoning: 'First', framework: :utilitarian
      )
      result = engine.resolve_dilemma(
        dilemma_id: dilemma_id, option_id: 'opt_b',
        reasoning: 'Second', framework: :deontological
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:already_resolved)
    end
  end

  describe '#apply_framework' do
    let(:dilemma_id) do
      engine.pose_dilemma(description: 'Framework test', options: options)[:dilemma][:id]
    end

    it 'returns rankings for a valid framework' do
      result = engine.apply_framework(dilemma_id: dilemma_id, framework: :utilitarian)
      expect(result[:success]).to be true
      expect(result[:rankings]).to be_an(Array)
      expect(result[:rankings].size).to eq(2)
    end

    it 'returns failure for unknown framework' do
      result = engine.apply_framework(dilemma_id: dilemma_id, framework: :made_up)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:unknown_framework)
    end

    it 'returns failure for unknown dilemma' do
      result = engine.apply_framework(dilemma_id: 'nope', framework: :utilitarian)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::ETHICAL_FRAMEWORKS.each do |framework|
      it "applies #{framework} framework" do
        result = engine.apply_framework(dilemma_id: dilemma_id, framework: framework)
        expect(result[:success]).to be true
        expect(result[:framework]).to eq(framework)
      end
    end
  end

  describe '#add_principle' do
    it 'adds a custom moral principle' do
      result = engine.add_principle(
        name:        'Do no harm',
        description: 'Avoid causing harm to others',
        foundation:  :care
      )
      expect(result[:success]).to be true
      expect(result[:principle][:name]).to eq('Do no harm')
    end

    it 'returns failure for unknown foundation' do
      result = engine.add_principle(name: 'Test', description: 'Test', foundation: :made_up)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:unknown_foundation)
    end

    it 'returns failure when max principles reached' do
      Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::MAX_PRINCIPLES.times do |i|
        engine.add_principle(name: "P#{i}", description: "Desc #{i}", foundation: :care)
      end
      result = engine.add_principle(name: 'One more', description: 'Extra', foundation: :care)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:max_principles_reached)
    end
  end

  describe '#moral_development' do
    context 'with insufficient resolved dilemmas' do
      it 'does not advance stage' do
        result = engine.moral_development
        expect(result[:advanced]).to be false
      end
    end

    context 'with enough high-severity resolved dilemmas' do
      before do
        5.times do |i|
          r = engine.pose_dilemma(description: "D#{i}", options: options, severity: 0.8)
          engine.resolve_dilemma(
            dilemma_id: r[:dilemma][:id], option_id: 'opt_a',
            reasoning: 'Because', framework: :utilitarian
          )
        end
      end

      it 'advances to the next Kohlberg stage' do
        result = engine.moral_development
        expect(result[:advanced]).to be true
        expect(result[:stage]).not_to eq(:social_contract)
      end
    end
  end

  describe '#foundation_profile' do
    it 'returns a hash keyed by foundation ids' do
      profile = engine.foundation_profile
      expect(profile.keys).to match_array(Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::MORAL_FOUNDATIONS)
    end
  end

  describe '#stage_info' do
    it 'returns stage, level, and description' do
      info = engine.stage_info
      expect(info).to include(:stage, :level, :description)
      expect(info[:stage]).to eq(:social_contract)
      expect(info[:level]).to eq(:postconventional)
    end
  end

  describe '#unresolved_dilemmas / #resolved_dilemmas' do
    before do
      engine.pose_dilemma(description: 'Unresolved', options: options)
      r = engine.pose_dilemma(description: 'Resolved', options: options)
      engine.resolve_dilemma(
        dilemma_id: r[:dilemma][:id], option_id: 'opt_a',
        reasoning: 'Because', framework: :utilitarian
      )
    end

    it 'returns only unresolved dilemmas' do
      expect(engine.unresolved_dilemmas.size).to eq(1)
      expect(engine.unresolved_dilemmas.first.resolved?).to be false
    end

    it 'returns only resolved dilemmas' do
      expect(engine.resolved_dilemmas.size).to eq(1)
      expect(engine.resolved_dilemmas.first.resolved?).to be true
    end
  end

  describe '#decay_all' do
    it 'decreases foundation weights' do
      profile_before = engine.foundation_profile.transform_values { |f| f[:weight] }
      engine.decay_all
      profile_after = engine.foundation_profile.transform_values { |f| f[:weight] }
      profile_before.each do |fid, before_weight|
        expect(profile_after[fid]).to be <= before_weight
      end
    end
  end

  describe '#to_h' do
    it 'returns a stats summary hash' do
      h = engine.to_h
      expect(h).to include(:stage, :total_dilemmas, :resolved_dilemmas,
                           :unresolved_dilemmas, :principles, :foundation_profile)
    end
  end
end
