# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Social::Calibration::Helpers::CalibrationRegistry do
  subject(:registry) { described_class.new }

  let(:identity_x) { 'user:alice' }
  let(:identity_y) { 'user:bob' }

  describe '#for(identity:)' do
    it 'returns a CalibrationStore instance' do
      expect(registry.for(identity: identity_x)).to be_a(
        Legion::Extensions::Agentic::Social::Calibration::Helpers::CalibrationStore
      )
    end

    it 'returns the same instance on repeated calls for the same identity' do
      first  = registry.for(identity: identity_x)
      second = registry.for(identity: identity_x)
      expect(first).to equal(second)
    end

    it 'returns independent instances per identity' do
      x = registry.for(identity: identity_x)
      y = registry.for(identity: identity_y)
      expect(x).not_to equal(y)
    end

    it 'X reads never see Y data — weights are independent' do
      store_x = registry.for(identity: identity_x)
      store_x.record_advisory(advisory_id: 'ax', advisory_types: [:tone_adjustment])
      store_x.evaluate_reaction(observation: { content: 'thanks, perfect!', direct_address: true, content_length: 20 })

      store_y = registry.for(identity: identity_y)
      expect(store_y.weights['tone_adjustment']).to eq(0.5)
    end

    it 'Y negative reaction never moves X calibration weights (contamination guard)' do
      store_x = registry.for(identity: identity_x)
      store_x.record_advisory(advisory_id: 'ax', advisory_types: [:tone_adjustment])

      store_y = registry.for(identity: identity_y)
      store_y.record_advisory(advisory_id: 'ay', advisory_types: [:tone_adjustment])
      store_y.evaluate_reaction(observation: { content: 'no, wrong', content_length: 5 })

      # X advisory meta should still be present (Y's reaction didn't consume X's advisory)
      result = store_x.evaluate_reaction(observation: { content: 'hello' })
      expect(result).not_to be_nil
    end
  end

  describe '#erase_partner!(identity:)' do
    before do
      store = registry.for(identity: identity_x)
      store.record_advisory(advisory_id: 'ax', advisory_types: [:tone_adjustment])
      store.evaluate_reaction(observation: { content: 'thanks' })

      registry.for(identity: identity_y)
    end

    it 'removes the store for the given identity' do
      registry.erase_partner!(identity: identity_x)
      # A new store is created — weights reset to neutral
      new_store = registry.for(identity: identity_x)
      expect(new_store.weights['tone_adjustment']).to eq(0.5)
      expect(new_store.history).to be_empty
    end

    it 'leaves other identities untouched' do
      store_y = registry.for(identity: identity_y)
      original_y = store_y.object_id
      registry.erase_partner!(identity: identity_x)
      expect(registry.for(identity: identity_y).object_id).to eq(original_y)
    end

    it 'returns true' do
      expect(registry.erase_partner!(identity: identity_x)).to be true
    end

    it 'returns true even when identity does not exist' do
      expect(registry.erase_partner!(identity: 'unknown')).to be true
    end
  end

  describe '#known_identities' do
    it 'returns empty array when no identities registered' do
      expect(registry.known_identities).to be_empty
    end

    it 'returns registered identities' do
      registry.for(identity: identity_x)
      registry.for(identity: identity_y)
      expect(registry.known_identities).to contain_exactly(identity_x, identity_y)
    end

    it 'does not include erased identities' do
      registry.for(identity: identity_x)
      registry.erase_partner!(identity: identity_x)
      expect(registry.known_identities).not_to include(identity_x)
    end
  end

  describe 'boot-order / idempotent registration' do
    it 're-registering an already-registered identity is a no-op (no duplicate store)' do
      first = registry.for(identity: identity_x)
      second = registry.for(identity: identity_x)
      expect(first).to equal(second)
    end
  end

  describe 'fail-closed guard' do
    it 'to_apollo_entries_for returns empty array when identity not registered' do
      expect(registry.to_apollo_entries_for(identity: 'unregistered')).to eq([])
    end

    it 'to_apollo_entries_for returns entries for a registered identity' do
      registry.for(identity: identity_x)
      entries = registry.to_apollo_entries_for(identity: identity_x)
      expect(entries).to be_an(Array)
      expect(entries).not_to be_empty
    end
  end
end
