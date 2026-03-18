# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Symbiosis::Helpers::SymbiosisEngine do
  subject(:engine) { described_class.new }

  describe '#create_bond' do
    it 'creates a mutualistic bond and returns created: true' do
      result = engine.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic)
      expect(result[:created]).to be true
      expect(result[:bond][:relationship_type]).to eq(:mutualistic)
    end

    it 'creates a parasitic bond' do
      result = engine.create_bond(subsystem_a: 'cortex', subsystem_b: 'tick', relationship_type: :parasitic)
      expect(result[:created]).to be true
    end

    it 'creates a commensal bond' do
      result = engine.create_bond(subsystem_a: 'trust', subsystem_b: 'identity', relationship_type: :commensal)
      expect(result[:created]).to be true
    end

    it 'returns created: false when bond already exists' do
      engine.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic)
      result = engine.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :commensal)
      expect(result[:created]).to be false
      expect(result[:reason]).to eq(:already_exists)
    end

    it 'returns created: false for invalid relationship_type' do
      result = engine.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :bogus)
      expect(result[:created]).to be false
      expect(result[:reason]).to eq(:invalid_arguments)
    end

    it 'accepts explicit strength' do
      result = engine.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic, strength: 0.9)
      expect(result[:bond][:strength]).to eq(0.9)
    end

    it 'accepts explicit benefit_ratio' do
      result = engine.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic, benefit_ratio: 0.75)
      expect(result[:bond][:benefit_ratio]).to eq(0.75)
    end
  end

  describe '#activate_interaction' do
    before { engine.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic) }

    it 'activates an existing bond' do
      result = engine.activate_interaction(subsystem_a: 'memory', subsystem_b: 'emotion')
      expect(result[:found]).to be true
    end

    it 'returns relationship_type in result' do
      result = engine.activate_interaction(subsystem_a: 'memory', subsystem_b: 'emotion')
      expect(result[:relationship_type]).to eq(:mutualistic)
    end

    it 'returns found: false for unknown pair' do
      result = engine.activate_interaction(subsystem_a: 'x', subsystem_b: 'y')
      expect(result[:found]).to be false
    end

    it 'works in reverse order' do
      result = engine.activate_interaction(subsystem_a: 'emotion', subsystem_b: 'memory')
      expect(result[:found]).to be true
    end
  end

  describe '#measure_ecosystem_health' do
    it 'returns a hash with score, label, bond_count, active_bonds, network_density' do
      result = engine.measure_ecosystem_health
      expect(result).to include(:score, :label, :bond_count, :active_bonds, :network_density)
    end

    it 'returns score 0.0 for fresh engine' do
      expect(engine.measure_ecosystem_health[:score]).to eq(0.0)
    end

    it 'returns higher score after adding mutualistic bonds' do
      engine.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic)
      expect(engine.measure_ecosystem_health[:score]).to be > 0
    end
  end

  describe '#find_partners' do
    before do
      engine.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic, strength: 0.7)
      engine.create_bond(subsystem_a: 'memory', subsystem_b: 'prediction', relationship_type: :parasitic, strength: 0.5)
      engine.create_bond(subsystem_a: 'trust', subsystem_b: 'consent', relationship_type: :mutualistic, strength: 0.6)
    end

    it 'returns partners of a subsystem with positive benefit_ratio by default' do
      partners = engine.find_partners('memory')
      subsystems = partners.map { |p| p[:partner] }
      expect(subsystems).to include('emotion')
    end

    it 'includes parasitic partners when min_benefit_ratio allows negatives' do
      partners = engine.find_partners('memory', min_benefit_ratio: -1.0)
      subsystems = partners.map { |p| p[:partner] }
      expect(subsystems).to include('emotion', 'prediction')
    end

    it 'filters by min_benefit_ratio to exclude parasitic' do
      partners = engine.find_partners('memory', min_benefit_ratio: 0.0)
      types = partners.map { |p| p[:relationship_type] }
      expect(types).not_to include(:parasitic)
    end

    it 'returns empty array for unknown subsystem' do
      expect(engine.find_partners('nobody')).to be_empty
    end

    it 'sorts by strength descending' do
      partners = engine.find_partners('memory', min_benefit_ratio: -1.0)
      strengths = partners.map { |p| p[:strength] }
      expect(strengths).to eq(strengths.sort.reverse)
    end
  end

  describe '#detect_parasites' do
    before do
      engine.create_bond(subsystem_a: 'cortex', subsystem_b: 'emotion', relationship_type: :parasitic, strength: 0.6)
      engine.create_bond(subsystem_a: 'memory', subsystem_b: 'trust', relationship_type: :mutualistic, strength: 0.5)
    end

    it 'returns only parasitic bonds' do
      result = engine.detect_parasites
      types = result.map { |b| b[:relationship_type] }
      expect(types).to all(eq(:parasitic))
    end

    it 'excludes bonds below strength_threshold' do
      result = engine.detect_parasites(strength_threshold: 0.8)
      expect(result).to be_empty
    end

    it 'returns dormant parasitic bonds when threshold is 0' do
      engine.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :parasitic, strength: 0.4)
      result = engine.detect_parasites
      expect(result.size).to be >= 1
    end
  end

  describe '#ecosystem_report' do
    before do
      engine.create_bond(subsystem_a: 'memory', subsystem_b: 'emotion', relationship_type: :mutualistic, strength: 0.5)
      engine.create_bond(subsystem_a: 'cortex', subsystem_b: 'tick', relationship_type: :parasitic, strength: 0.4)
    end

    it 'returns expected keys' do
      report = engine.ecosystem_report
      expect(report).to include(:health, :bonds_by_type, :most_beneficial, :most_parasitic, :total_bonds, :dormant_bonds)
    end

    it 'bonds_by_type contains all three relationship types' do
      report = engine.ecosystem_report
      expect(report[:bonds_by_type].keys).to include(:mutualistic, :parasitic, :commensal)
    end

    it 'total_bonds matches registered count' do
      report = engine.ecosystem_report
      expect(report[:total_bonds]).to eq(2)
    end

    it 'most_beneficial refers to mutualistic bond' do
      report = engine.ecosystem_report
      expect(report[:most_beneficial][:relationship_type]).to eq(:mutualistic)
    end
  end

  describe '#decay_all' do
    it 'returns decayed count and health_after' do
      engine.create_bond(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic)
      result = engine.decay_all
      expect(result).to include(:decayed, :health_after)
      expect(result[:decayed]).to eq(1)
    end
  end
end
