# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::SocialLearning::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:register_model_agent)
    expect(client).to respond_to(:observe_agent_behavior)
    expect(client).to respond_to(:retained_behaviors)
    expect(client).to respond_to(:reproducible_behaviors)
    expect(client).to respond_to(:reproduce_observed_behavior)
    expect(client).to respond_to(:reinforce_reproduction)
    expect(client).to respond_to(:best_model_agents)
    expect(client).to respond_to(:domain_models)
    expect(client).to respond_to(:update_social_learning)
    expect(client).to respond_to(:social_learning_stats)
  end

  it 'accepts an injected engine' do
    engine = Legion::Extensions::Agentic::Social::SocialLearning::Helpers::SocialLearningEngine.new
    injected_client = described_class.new(engine: engine)
    result = injected_client.social_learning_stats
    expect(result[:success]).to be true
  end
end
