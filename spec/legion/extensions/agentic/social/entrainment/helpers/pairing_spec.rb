# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Entrainment::Helpers::Pairing do
  subject(:pairing) do
    described_class.new(agent_a: 'alpha', agent_b: 'beta', domain: :reasoning)
  end

  describe '#initialize' do
    it 'assigns a UUID' do
      expect(pairing.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'starts with zero synchrony' do
      expect(pairing.synchrony).to eq(0.0)
    end
  end

  describe '#interact!' do
    it 'increases synchrony on aligned interaction' do
      pairing.interact!(aligned: true)
      expect(pairing.synchrony).to be > 0.0
    end

    it 'decreases synchrony on misaligned interaction' do
      3.times { pairing.interact!(aligned: true) }
      original = pairing.synchrony
      pairing.interact!(aligned: false)
      expect(pairing.synchrony).to be < original
    end

    it 'increments interaction count' do
      expect { pairing.interact!(aligned: true) }.to change(pairing, :interaction_count).by(1)
    end
  end

  describe '#drift!' do
    it 'reduces synchrony' do
      3.times { pairing.interact!(aligned: true) }
      original = pairing.synchrony
      pairing.drift!
      expect(pairing.synchrony).to be < original
    end
  end

  describe '#entrained?' do
    it 'returns false initially' do
      expect(pairing).not_to be_entrained
    end

    it 'returns true after many aligned interactions' do
      10.times { pairing.interact!(aligned: true) }
      expect(pairing).to be_entrained
    end
  end

  describe '#partially_entrained?' do
    it 'returns true at moderate synchrony' do
      5.times { pairing.interact!(aligned: true) }
      expect(pairing).to be_partially_entrained
    end
  end

  describe '#sync_label' do
    it 'returns a symbol' do
      expect(pairing.sync_label).to be_a(Symbol)
    end
  end

  describe '#involves?' do
    it 'returns true for agent_a' do
      expect(pairing.involves?('alpha')).to be true
    end

    it 'returns true for agent_b' do
      expect(pairing.involves?('beta')).to be true
    end

    it 'returns false for other agent' do
      expect(pairing.involves?('gamma')).to be false
    end
  end

  describe '#partner_of' do
    it 'returns agent_b for agent_a' do
      expect(pairing.partner_of('alpha')).to eq('beta')
    end

    it 'returns agent_a for agent_b' do
      expect(pairing.partner_of('beta')).to eq('alpha')
    end

    it 'returns nil for unknown agent' do
      expect(pairing.partner_of('gamma')).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      hash = pairing.to_h
      expect(hash).to include(:id, :agent_a, :agent_b, :synchrony, :entrained)
    end
  end
end
