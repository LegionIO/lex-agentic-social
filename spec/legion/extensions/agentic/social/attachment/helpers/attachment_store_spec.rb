# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/social/attachment/helpers/constants'
require 'legion/extensions/agentic/social/attachment/helpers/attachment_model'
require 'legion/extensions/agentic/social/attachment/helpers/attachment_store'

RSpec.describe Legion::Extensions::Agentic::Social::Attachment::Helpers::AttachmentStore do
  subject(:store) { described_class.new }

  describe '#get' do
    it 'returns nil for unknown agent' do
      expect(store.get('unknown')).to be_nil
    end
  end

  describe '#get_or_create' do
    it 'creates a new model for unknown agent' do
      model = store.get_or_create('agent-1')
      expect(model).to be_a(Legion::Extensions::Agentic::Social::Attachment::Helpers::AttachmentModel)
      expect(model.agent_id).to eq('agent-1')
    end

    it 'returns existing model on second call' do
      first  = store.get_or_create('agent-1')
      second = store.get_or_create('agent-1')
      expect(first).to equal(second)
    end
  end

  describe '#dirty?' do
    it 'starts clean' do
      expect(store).not_to be_dirty
    end

    it 'becomes dirty after get_or_create' do
      store.get_or_create('agent-1')
      expect(store).to be_dirty
    end
  end

  describe '#mark_clean!' do
    it 'clears dirty flag' do
      store.get_or_create('agent-1')
      store.mark_clean!
      expect(store).not_to be_dirty
    end

    it 'returns self for chaining' do
      expect(store.mark_clean!).to eq(store)
    end
  end

  describe '#to_apollo_entries' do
    before { store.get_or_create('partner-1') }

    it 'returns an array of entry hashes' do
      entries = store.to_apollo_entries
      expect(entries).to be_an(Array)
      expect(entries.size).to eq(1)
    end

    it 'includes content and tags' do
      entry = store.to_apollo_entries.first
      expect(entry).to have_key(:content)
      expect(entry).to have_key(:tags)
    end

    it 'tags with bond, attachment, and agent_id' do
      entry = store.to_apollo_entries.first
      expect(entry[:tags]).to include('bond', 'attachment', 'partner-1')
    end

    it 'adds partner tag when BondRegistry says partner' do
      bond_registry = class_double('Legion::Gaia::BondRegistry')
      stub_const('Legion::Gaia::BondRegistry', bond_registry)
      allow(bond_registry).to receive(:partner?).with('partner-1').and_return(true)
      entry = store.to_apollo_entries.first
      expect(entry[:tags]).to include('partner')
    end
  end

  describe '#from_apollo' do
    let(:mock_store) { double('apollo_local') }

    it 'restores models from query results' do
      model = Legion::Extensions::Agentic::Social::Attachment::Helpers::AttachmentModel.new(agent_id: 'p1')
      model.instance_variable_set(:@attachment_strength, 0.6)
      model.instance_variable_set(:@bond_stage, :established)
      content = Legion::JSON.dump(model.to_h) if defined?(Legion::JSON)
      content ||= JSON.dump(model.to_h)

      allow(mock_store).to receive(:query)
        .with(text: 'bond attachment', tags: %w[bond attachment])
        .and_return({ success: true, results: [{ content: content, tags: %w[bond attachment p1] }] })

      result = store.from_apollo(store: mock_store)
      expect(result).to be true
      expect(store.get('p1')).not_to be_nil
      expect(store.get('p1').attachment_strength).to eq(0.6)
    end

    it 'returns false on empty results' do
      allow(mock_store).to receive(:query).and_return({ success: true, results: [] })
      expect(store.from_apollo(store: mock_store)).to be false
    end

    it 'returns false on error' do
      allow(mock_store).to receive(:query).and_raise(StandardError, 'db error')
      expect(store.from_apollo(store: mock_store)).to be false
    end
  end

  describe '#all_models' do
    it 'returns all tracked models' do
      store.get_or_create('a1')
      store.get_or_create('a2')
      expect(store.all_models.size).to eq(2)
    end
  end
end
