# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Symbiosis::Helpers::SymbioticBond do
  let(:bond) do
    described_class.new(
      subsystem_a:       'memory',
      subsystem_b:       'emotion',
      relationship_type: :mutualistic
    )
  end

  describe '#initialize' do
    it 'assigns subsystem_a and subsystem_b' do
      expect(bond.subsystem_a).to eq('memory')
      expect(bond.subsystem_b).to eq('emotion')
    end

    it 'assigns relationship_type' do
      expect(bond.relationship_type).to eq(:mutualistic)
    end

    it 'assigns a uuid bond_id' do
      expect(bond.bond_id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets default strength when not provided' do
      expect(bond.strength).to eq(
        Legion::Extensions::Agentic::Social::Symbiosis::Helpers::Constants::DEFAULT_STRENGTH
      )
    end

    it 'clamps strength to 0.0..1.0' do
      b = described_class.new(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic, strength: 5.0)
      expect(b.strength).to eq(1.0)
    end

    it 'clamps negative strength to 0.0' do
      b = described_class.new(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic, strength: -1.0)
      expect(b.strength).to eq(0.0)
    end

    it 'assigns a positive benefit_ratio for mutualistic by default' do
      expect(bond.benefit_ratio).to be > 0
    end

    it 'assigns a negative benefit_ratio for parasitic by default' do
      b = described_class.new(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :parasitic)
      expect(b.benefit_ratio).to be < 0
    end

    it 'accepts explicit benefit_ratio' do
      b = described_class.new(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic, benefit_ratio: 0.8)
      expect(b.benefit_ratio).to eq(0.8)
    end

    it 'sets activation_count to 0' do
      expect(bond.activation_count).to eq(0)
    end

    it 'sets last_activated_at to nil' do
      expect(bond.last_activated_at).to be_nil
    end

    it 'raises ArgumentError for unknown relationship_type' do
      expect do
        described_class.new(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :unknown)
      end.to raise_error(ArgumentError, /unknown relationship_type/)
    end
  end

  describe '#activate!' do
    it 'increases strength' do
      before = bond.strength
      bond.activate!(amount: 0.1)
      expect(bond.strength).to be > before
    end

    it 'increments activation_count' do
      bond.activate!
      expect(bond.activation_count).to eq(1)
    end

    it 'sets last_activated_at' do
      bond.activate!
      expect(bond.last_activated_at).not_to be_nil
    end

    it 'does not exceed MAX_STRENGTH' do
      bond.activate!(amount: 10.0)
      expect(bond.strength).to eq(1.0)
    end

    it 'clamps amount to 1.0 max' do
      bond.activate!(amount: 99.0)
      expect(bond.strength).to eq(1.0)
    end

    it 'returns self for chaining' do
      expect(bond.activate!).to be(bond)
    end
  end

  describe '#decay!' do
    it 'decreases strength' do
      bond.activate!(amount: 0.5)
      before = bond.strength
      bond.decay!
      expect(bond.strength).to be < before
    end

    it 'does not go below MIN_STRENGTH' do
      50.times { bond.decay! }
      expect(bond.strength).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(bond.decay!).to be(bond)
    end
  end

  describe '#dormant?' do
    it 'returns true when strength is at or below DORMANT_THRESHOLD' do
      b = described_class.new(
        subsystem_a: 'a', subsystem_b: 'b', relationship_type: :commensal,
        strength: Legion::Extensions::Agentic::Social::Symbiosis::Helpers::Constants::DORMANT_THRESHOLD
      )
      expect(b.dormant?).to be true
    end

    it 'returns false for active bond' do
      bond.activate!(amount: 0.5)
      expect(bond.dormant?).to be false
    end
  end

  describe '#strong?' do
    it 'returns false by default' do
      expect(bond.strong?).to be false
    end

    it 'returns true when strength meets STRONG_THRESHOLD' do
      b = described_class.new(
        subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic,
        strength: Legion::Extensions::Agentic::Social::Symbiosis::Helpers::Constants::STRONG_THRESHOLD
      )
      expect(b.strong?).to be true
    end
  end

  describe '#strength_label' do
    it 'returns :dormant for very low strength' do
      b = described_class.new(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :commensal, strength: 0.01)
      expect(b.strength_label).to eq(:dormant)
    end

    it 'returns :dominant for very high strength' do
      b = described_class.new(subsystem_a: 'a', subsystem_b: 'b', relationship_type: :mutualistic, strength: 0.95)
      expect(b.strength_label).to eq(:dominant)
    end
  end

  describe '#involves?' do
    it 'returns true when subsystem_a matches' do
      expect(bond.involves?('memory')).to be true
    end

    it 'returns true when subsystem_b matches' do
      expect(bond.involves?('emotion')).to be true
    end

    it 'returns false for unrelated subsystem' do
      expect(bond.involves?('prediction')).to be false
    end
  end

  describe '#partner_of' do
    it 'returns subsystem_b when given subsystem_a' do
      expect(bond.partner_of('memory')).to eq('emotion')
    end

    it 'returns subsystem_a when given subsystem_b' do
      expect(bond.partner_of('emotion')).to eq('memory')
    end

    it 'returns nil for unknown subsystem' do
      expect(bond.partner_of('unknown')).to be_nil
    end
  end

  describe '#to_h' do
    it 'includes all required keys' do
      h = bond.to_h
      expect(h).to include(
        :bond_id, :subsystem_a, :subsystem_b, :relationship_type,
        :strength, :strength_label, :benefit_ratio, :activation_count,
        :dormant, :strong, :created_at, :last_activated_at
      )
    end

    it 'last_activated_at is nil before first activation' do
      expect(bond.to_h[:last_activated_at]).to be_nil
    end

    it 'last_activated_at is an ISO8601 string after activation' do
      bond.activate!
      expect(bond.to_h[:last_activated_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end
end
