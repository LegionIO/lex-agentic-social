# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::SocialLearning::Runners::SocialLearning do
  let(:client) { Legion::Extensions::Agentic::Social::SocialLearning::Client.new }

  describe '#register_model_agent' do
    it 'returns success with model hash' do
      result = client.register_model_agent(agent_id: 'agent-1', domain: :coding)
      expect(result[:success]).to be true
      expect(result[:model]).to include(:id, :agent_id, :domain, :prestige)
    end

    it 'accepts custom prestige' do
      result = client.register_model_agent(agent_id: 'agent-1', domain: :coding, prestige: 0.8)
      expect(result[:model][:prestige]).to eq(0.8)
    end
  end

  describe '#observe_agent_behavior' do
    let(:model_id) do
      client.register_model_agent(agent_id: 'agent-1', domain: :coding)[:model][:id]
    end

    it 'returns success with behavior hash when model passes attention threshold' do
      result = client.observe_agent_behavior(
        model_id: model_id, action: 'write_test', domain: :coding, outcome: :positive
      )
      expect(result[:success]).to be true
      expect(result[:behavior]).to include(:id, :action, :retention)
    end

    it 'returns success: false for unknown model_id' do
      result = client.observe_agent_behavior(
        model_id: 'nonexistent', action: 'do_thing', domain: :coding, outcome: :positive
      )
      expect(result[:success]).to be false
    end
  end

  describe '#retained_behaviors' do
    before do
      model_id = client.register_model_agent(agent_id: 'agent-1', domain: :coding)[:model][:id]
      client.observe_agent_behavior(
        model_id: model_id, action: 'write_test', domain: :coding, outcome: :positive
      )
    end

    it 'returns behaviors with count' do
      result = client.retained_behaviors
      expect(result[:success]).to be true
      expect(result).to include(:behaviors, :count)
    end

    it 'filters by domain' do
      result = client.retained_behaviors(domain: :coding)
      expect(result[:behaviors].all? { |beh| beh[:domain] == :coding }).to be true
    end
  end

  describe '#reproducible_behaviors' do
    it 'returns success: true with behaviors list' do
      result = client.reproducible_behaviors
      expect(result[:success]).to be true
      expect(result).to include(:behaviors, :count)
    end
  end

  describe '#reproduce_observed_behavior' do
    let(:behavior_id) do
      model_id = client.register_model_agent(agent_id: 'agent-1', domain: :coding)[:model][:id]
      client.observe_agent_behavior(
        model_id: model_id, action: 'write_test', domain: :coding, outcome: :positive
      )[:behavior][:id]
    end

    it 'returns success with reproduced behavior' do
      result = client.reproduce_observed_behavior(behavior_id: behavior_id)
      expect(result[:success]).to be true
      expect(result[:behavior][:reproduced]).to be true
    end

    it 'returns success: false for unknown behavior_id' do
      result = client.reproduce_observed_behavior(behavior_id: 'nonexistent')
      expect(result[:success]).to be false
    end
  end

  describe '#reinforce_reproduction' do
    let(:behavior_id) do
      model_id = client.register_model_agent(agent_id: 'agent-1', domain: :coding)[:model][:id]
      client.observe_agent_behavior(
        model_id: model_id, action: 'write_test', domain: :coding, outcome: :positive
      )[:behavior][:id]
    end

    it 'returns success with model_prestige on positive outcome' do
      result = client.reinforce_reproduction(behavior_id: behavior_id, outcome: :positive)
      expect(result[:success]).to be true
      expect(result[:model_prestige]).to be_a(Float)
    end

    it 'returns success: false for unknown behavior_id' do
      result = client.reinforce_reproduction(behavior_id: 'nonexistent', outcome: :positive)
      expect(result[:success]).to be false
    end
  end

  describe '#best_model_agents' do
    before do
      client.register_model_agent(agent_id: 'agent-1', domain: :coding, prestige: 0.9)
      client.register_model_agent(agent_id: 'agent-2', domain: :ops,    prestige: 0.4)
    end

    it 'returns models sorted by prestige' do
      result = client.best_model_agents(limit: 2)
      expect(result[:success]).to be true
      prestiges = result[:models].map { |mod| mod[:prestige] }
      expect(prestiges).to eq(prestiges.sort.reverse)
    end
  end

  describe '#domain_models' do
    before do
      client.register_model_agent(agent_id: 'agent-1', domain: :coding)
      client.register_model_agent(agent_id: 'agent-2', domain: :ops)
    end

    it 'returns only models for the given domain' do
      result = client.domain_models(domain: :coding)
      expect(result[:success]).to be true
      expect(result[:models].all? { |mod| mod[:domain] == :coding }).to be true
    end
  end

  describe '#update_social_learning' do
    it 'returns success with stats' do
      result = client.update_social_learning
      expect(result[:success]).to be true
      expect(result).to include(:model_count, :behavior_count)
    end
  end

  describe '#social_learning_stats' do
    it 'returns success with stats hash' do
      result = client.social_learning_stats
      expect(result[:success]).to be true
      expect(result).to include(:model_count, :behavior_count, :retained_count, :reproducible_count)
    end
  end
end
