# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Symbiosis::Helpers::Ecosystem do
  subject(:ecosystem) { described_class.new }

  let(:bond_class) { Legion::Extensions::Agentic::Social::Symbiosis::Helpers::SymbioticBond }
  let(:constants)  { Legion::Extensions::Agentic::Social::Symbiosis::Helpers::Constants }

  def make_bond(sys_a, sys_b, rel_type, strength: 0.5)
    bond_class.new(subsystem_a: sys_a, subsystem_b: sys_b, relationship_type: rel_type, strength: strength)
  end

  describe '#register_bond' do
    it 'registers a bond and returns it' do
      bond = make_bond('memory', 'emotion', :mutualistic)
      result = ecosystem.register_bond(bond)
      expect(result).to be(bond)
    end

    it 'increments bond_count' do
      ecosystem.register_bond(make_bond('a', 'b', :mutualistic))
      expect(ecosystem.bond_count).to eq(1)
    end

    it 'raises ArgumentError for non-bond object' do
      expect { ecosystem.register_bond('not_a_bond') }.to raise_error(ArgumentError, /must be a SymbioticBond/)
    end

    it 'raises ArgumentError when MAX_BONDS exceeded' do
      constants::MAX_BONDS.times do |i|
        b = bond_class.new(subsystem_a: "sys#{i}a", subsystem_b: "sys#{i}b", relationship_type: :commensal)
        ecosystem.register_bond(b)
      end
      extra = make_bond('overflow_a', 'overflow_b', :mutualistic)
      expect { ecosystem.register_bond(extra) }.to raise_error(ArgumentError, /MAX_BONDS/)
    end
  end

  describe '#activate_bond' do
    let(:bond) { make_bond('memory', 'emotion', :mutualistic) }

    before { ecosystem.register_bond(bond) }

    it 'returns found: true for existing bond' do
      result = ecosystem.activate_bond(bond.bond_id)
      expect(result[:found]).to be true
    end

    it 'increases strength on activation' do
      before = bond.strength
      ecosystem.activate_bond(bond.bond_id, amount: 0.1)
      expect(bond.strength).to be > before
    end

    it 'returns found: false for unknown bond_id' do
      result = ecosystem.activate_bond('nonexistent')
      expect(result[:found]).to be false
    end
  end

  describe '#measure_health' do
    it 'returns 0.0 for empty ecosystem' do
      expect(ecosystem.measure_health).to eq(0.0)
    end

    it 'returns higher score for more mutualistic bonds' do
      3.times { |i| ecosystem.register_bond(make_bond("m#{i}a", "m#{i}b", :mutualistic)) }
      expect(ecosystem.measure_health).to be > 0.5
    end

    it 'returns lower score when parasitic bonds present' do
      ecosystem.register_bond(make_bond('a', 'b', :mutualistic))
      ecosystem.register_bond(make_bond('c', 'd', :parasitic))
      expect(ecosystem.measure_health).to be < 1.0
    end

    it 'returns 0.0 when only dormant bonds exist' do
      dormant = make_bond('a', 'b', :mutualistic, strength: 0.0)
      ecosystem.register_bond(dormant)
      expect(ecosystem.measure_health).to eq(0.0)
    end
  end

  describe '#health_label' do
    it 'returns :critical for empty ecosystem' do
      expect(ecosystem.health_label).to eq(:critical)
    end

    it 'returns a symbol label' do
      ecosystem.register_bond(make_bond('a', 'b', :mutualistic))
      expect(ecosystem.health_label).to be_a(Symbol)
    end
  end

  describe '#most_beneficial' do
    it 'returns nil when no mutualistic bonds' do
      ecosystem.register_bond(make_bond('a', 'b', :parasitic))
      expect(ecosystem.most_beneficial).to be_nil
    end

    it 'returns the mutualistic bond with highest benefit*strength' do
      low  = bond_class.new(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic, strength: 0.3, benefit_ratio: 0.2)
      high = bond_class.new(subsystem_a: 'c', subsystem_b: 'd', relationship_type: :mutualistic, strength: 0.9, benefit_ratio: 0.9)
      ecosystem.register_bond(low)
      ecosystem.register_bond(high)
      expect(ecosystem.most_beneficial).to be(high)
    end
  end

  describe '#most_parasitic' do
    it 'returns nil when no parasitic bonds' do
      ecosystem.register_bond(make_bond('a', 'b', :mutualistic))
      expect(ecosystem.most_parasitic).to be_nil
    end

    it 'returns parasitic bond' do
      ecosystem.register_bond(make_bond('x', 'y', :parasitic))
      expect(ecosystem.most_parasitic).not_to be_nil
    end
  end

  describe '#decay_all!' do
    it 'decays all bonds and returns count' do
      3.times { |i| ecosystem.register_bond(make_bond("a#{i}", "b#{i}", :mutualistic)) }
      count = ecosystem.decay_all!
      expect(count).to eq(3)
    end
  end

  describe '#network_density' do
    it 'returns 0.0 for empty ecosystem' do
      expect(ecosystem.network_density).to eq(0.0)
    end

    it 'returns average strength of active bonds' do
      ecosystem.register_bond(make_bond('a', 'b', :mutualistic, strength: 0.8))
      ecosystem.register_bond(make_bond('c', 'd', :mutualistic, strength: 0.4))
      expect(ecosystem.network_density).to be_within(0.01).of(0.6)
    end
  end

  describe '#symbiotic_web' do
    it 'returns all bonds involving a subsystem' do
      ecosystem.register_bond(make_bond('memory', 'emotion', :mutualistic))
      ecosystem.register_bond(make_bond('memory', 'prediction', :commensal))
      ecosystem.register_bond(make_bond('trust', 'consent', :mutualistic))
      web = ecosystem.symbiotic_web('memory')
      expect(web.size).to eq(2)
    end

    it 'returns empty array for unknown subsystem' do
      expect(ecosystem.symbiotic_web('nobody')).to be_empty
    end
  end

  describe '#find_bond' do
    before { ecosystem.register_bond(make_bond('alpha', 'beta', :mutualistic)) }

    it 'finds bond by exact pair' do
      expect(ecosystem.find_bond('alpha', 'beta')).not_to be_nil
    end

    it 'finds bond in reverse order' do
      expect(ecosystem.find_bond('beta', 'alpha')).not_to be_nil
    end

    it 'returns nil for unknown pair' do
      expect(ecosystem.find_bond('x', 'y')).to be_nil
    end
  end

  describe '#all_bonds / #active_bonds' do
    it 'all_bonds returns all including dormant' do
      ecosystem.register_bond(make_bond('a', 'b', :commensal, strength: 0.0))
      ecosystem.register_bond(make_bond('c', 'd', :mutualistic, strength: 0.5))
      expect(ecosystem.all_bonds.size).to eq(2)
    end

    it 'active_bonds excludes dormant bonds' do
      ecosystem.register_bond(make_bond('a', 'b', :commensal, strength: 0.0))
      ecosystem.register_bond(make_bond('c', 'd', :mutualistic, strength: 0.5))
      expect(ecosystem.active_bonds.size).to eq(1)
    end
  end
end
