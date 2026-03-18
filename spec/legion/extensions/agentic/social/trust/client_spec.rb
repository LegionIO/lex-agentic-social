# frozen_string_literal: true

require 'legion/extensions/agentic/social/trust/client'

RSpec.describe Legion::Extensions::Agentic::Social::Trust::Client do
  let(:client) { described_class.new }

  it 'responds to trust runner methods' do
    expect(client).to respond_to(:get_trust)
    expect(client).to respond_to(:record_trust_interaction)
    expect(client).to respond_to(:reinforce_trust_dimension)
    expect(client).to respond_to(:decay_trust)
    expect(client).to respond_to(:trusted_agents)
    expect(client).to respond_to(:delegatable_agents)
    expect(client).to respond_to(:trust_status)
  end
end
