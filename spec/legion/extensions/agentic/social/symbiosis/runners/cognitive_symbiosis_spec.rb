# frozen_string_literal: true

require 'legion/extensions/agentic/social/symbiosis/client'

RSpec.describe Legion::Extensions::Agentic::Social::Symbiosis::Runners::CognitiveSymbiosis do
  let(:client) { Legion::Extensions::Agentic::Social::Symbiosis::Client.new }
  let(:engine) { Legion::Extensions::Agentic::Social::Symbiosis::Helpers::SymbiosisEngine.new }

  describe '#create_bond' do
    it 'creates a mutualistic bond' do
      result = client.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic)
      expect(result[:success]).to be true
      expect(result[:bond][:relationship_type]).to eq(:mutualistic)
    end

    it 'creates a parasitic bond' do
      result = client.create_bond(subsystem_a: 'cortex', subsystem_b: 'tick', relationship_type: :parasitic)
      expect(result[:success]).to be true
    end

    it 'creates a commensal bond' do
      result = client.create_bond(subsystem_a: 'trust', subsystem_b: 'identity', relationship_type: :commensal)
      expect(result[:success]).to be true
    end

    it 'returns success: false for duplicate bond' do
      client.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic)
      result = client.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic)
      expect(result[:success]).to be false
    end

    it 'returns success: false for invalid relationship_type' do
      result = client.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :invalid)
      expect(result[:success]).to be false
      expect(result[:error]).to be_a(String)
    end

    it 'uses injected engine' do
      result = client.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic, engine: engine)
      expect(result[:success]).to be true
    end

    it 'ignores extra keyword arguments via ** splat' do
      result = client.create_bond(subsystem_a: 'x', subsystem_b: 'y', relationship_type: :commensal, extra: :ignored)
      expect(result[:success]).to be true
    end
  end

  describe '#activate' do
    before { client.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic) }

    it 'activates an existing bond' do
      result = client.activate(subsystem_a: 'memory', subsystem_b: 'emotion')
      expect(result[:success]).to be true
    end

    it 'returns success: false for unknown pair' do
      result = client.activate(subsystem_a: 'x', subsystem_b: 'y')
      expect(result[:success]).to be false
    end

    it 'includes relationship_type in result' do
      result = client.activate(subsystem_a: 'memory', subsystem_b: 'emotion')
      expect(result[:relationship_type]).to eq(:mutualistic)
    end

    it 'clamps amount to 1.0' do
      result = client.activate(subsystem_a: 'memory', subsystem_b: 'emotion', amount: 99.0)
      expect(result[:success]).to be true
    end

    it 'uses injected engine' do
      engine.create_bond(subsystem_a: 'p', subsystem_b: 'q', relationship_type: :commensal)
      result = client.activate(subsystem_a: 'p', subsystem_b: 'q', engine: engine)
      expect(result[:success]).to be true
    end
  end

  describe '#health_status' do
    it 'returns success: true' do
      result = client.health_status
      expect(result[:success]).to be true
    end

    it 'includes score and label' do
      result = client.health_status
      expect(result).to include(:score, :label)
    end

    it 'label improves after adding mutualistic bonds' do
      client.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic)
      result = client.health_status
      expect(result[:score]).to be >= 0
    end
  end

  describe '#list_bonds' do
    before do
      client.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic)
      client.create_bond(subsystem_a: 'cortex', subsystem_b: 'tick', relationship_type: :parasitic)
      client.create_bond(subsystem_a: 'memory', subsystem_b: 'trust', relationship_type: :commensal)
    end

    it 'returns all bonds when no filter' do
      result = client.list_bonds
      expect(result[:success]).to be true
      expect(result[:count]).to eq(3)
    end

    it 'filters by subsystem_id' do
      result = client.list_bonds(subsystem_id: 'memory')
      expect(result[:count]).to eq(2)
    end

    it 'filters by relationship_type' do
      result = client.list_bonds(relationship_type: :mutualistic)
      types = result[:bonds].map { |b| b[:relationship_type] }
      expect(types).to all(eq(:mutualistic))
    end

    it 'returns empty bonds for unknown subsystem' do
      result = client.list_bonds(subsystem_id: 'nobody')
      expect(result[:count]).to eq(0)
    end
  end

  describe '#detect_parasites' do
    before do
      client.create_bond(subsystem_a: 'cortex', subsystem_b: 'emotion', relationship_type: :parasitic)
      client.create_bond(subsystem_a: 'memory', subsystem_b: 'trust', relationship_type: :mutualistic)
    end

    it 'returns success: true' do
      result = client.detect_parasites
      expect(result[:success]).to be true
    end

    it 'returns only parasitic bonds' do
      result = client.detect_parasites
      types = result[:parasites].map { |b| b[:relationship_type] }
      expect(types).to all(eq(:parasitic))
    end

    it 'includes count' do
      result = client.detect_parasites
      expect(result[:count]).to be_a(Integer)
    end

    it 'filters by strength_threshold' do
      result = client.detect_parasites(strength_threshold: 0.99)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#ecosystem_report' do
    before do
      client.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic)
    end

    it 'returns success: true' do
      result = client.ecosystem_report
      expect(result[:success]).to be true
    end

    it 'includes bonds_by_type for all three types' do
      result = client.ecosystem_report
      expect(result[:bonds_by_type].keys).to include(:mutualistic, :parasitic, :commensal)
    end

    it 'total_bonds is correct' do
      result = client.ecosystem_report
      expect(result[:total_bonds]).to eq(1)
    end

    it 'uses injected engine' do
      engine.create_bond(subsystem_a: 'p', subsystem_b: 'q', relationship_type: :commensal)
      result = client.ecosystem_report(engine: engine)
      expect(result[:success]).to be true
      expect(result[:total_bonds]).to eq(1)
    end
  end
end
