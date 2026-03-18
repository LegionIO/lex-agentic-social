# frozen_string_literal: true

require 'legion/extensions/agentic/social/symbiosis/client'

RSpec.describe Legion::Extensions::Agentic::Social::Symbiosis::Client do
  subject(:client) { described_class.new }

  it 'responds to create_bond' do
    expect(client).to respond_to(:create_bond)
  end

  it 'responds to activate' do
    expect(client).to respond_to(:activate)
  end

  it 'responds to health_status' do
    expect(client).to respond_to(:health_status)
  end

  it 'responds to list_bonds' do
    expect(client).to respond_to(:list_bonds)
  end

  it 'responds to detect_parasites' do
    expect(client).to respond_to(:detect_parasites)
  end

  it 'responds to ecosystem_report' do
    expect(client).to respond_to(:ecosystem_report)
  end

  it 'creates a fresh engine per instance' do
    c1 = described_class.new
    c2 = described_class.new
    c1.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic)
    expect(c2.list_bonds[:count]).to eq(0)
  end

  it 'maintains state across calls on same instance' do
    client.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic)
    expect(client.list_bonds[:count]).to eq(1)
    client.create_bond(subsystem_a: 'trust', subsystem_b: 'consent', relationship_type: :mutualistic)
    expect(client.list_bonds[:count]).to eq(2)
  end
end
