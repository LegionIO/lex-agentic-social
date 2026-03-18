# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::SocialLearning::Helpers::ObservedBehavior do
  subject(:behavior) do
    described_class.new(
      model_agent_id: 'model-123',
      action:         'write_test',
      domain:         :coding,
      outcome:        :positive,
      context:        { language: 'ruby' }
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(behavior.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets retention to 1.0' do
      expect(behavior.retention).to eq(1.0)
    end

    it 'sets reproduced to false' do
      expect(behavior.reproduced).to be false
    end

    it 'stores the action' do
      expect(behavior.action).to eq('write_test')
    end

    it 'stores the domain' do
      expect(behavior.domain).to eq(:coding)
    end

    it 'stores the outcome' do
      expect(behavior.outcome).to eq(:positive)
    end

    it 'stores context' do
      expect(behavior.context).to eq({ language: 'ruby' })
    end
  end

  describe '#decay_retention!' do
    it 'reduces retention by RETENTION_DECAY' do
      before = behavior.retention
      behavior.decay_retention!
      expect(behavior.retention).to be < before
    end

    it 'does not go below 0.0' do
      50.times { behavior.decay_retention! }
      expect(behavior.retention).to be >= 0.0
    end
  end

  describe '#retained?' do
    it 'returns true when retention is above REPRODUCTION_CONFIDENCE' do
      expect(behavior.retained?).to be true
    end

    it 'returns false when retention has decayed below threshold' do
      behavior.retention = 0.4
      expect(behavior.retained?).to be false
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      hash = behavior.to_h
      expect(hash).to include(:id, :model_agent_id, :action, :domain, :outcome,
                              :retention, :reproduced, :retained, :created_at)
    end

    it 'rounds retention to 4 decimal places' do
      behavior.decay_retention!
      hash = behavior.to_h
      expect(hash[:retention].to_s.split('.').last.length).to be <= 4
    end
  end
end
