# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Social::Conflict::Helpers::ConflictLog do
  subject(:log) { described_class.new }

  let(:parties)     { %w[agent human] }
  let(:severity)    { :high }
  let(:description) { 'disagreement over shutdown procedure' }

  describe '#initialize' do
    it 'starts with an empty conflicts hash' do
      expect(log.conflicts).to eq({})
    end
  end

  describe '#record' do
    it 'returns a UUID string' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it 'stores the conflict under the returned id' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id]).not_to be_nil
    end

    it 'sets conflict_id on the record' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id][:conflict_id]).to eq(id)
    end

    it 'stores the parties array' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id][:parties]).to eq(parties)
    end

    it 'stores the severity' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id][:severity]).to eq(:high)
    end

    it 'stores the description' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id][:description]).to eq(description)
    end

    it 'sets status to :active' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id][:status]).to eq(:active)
    end

    it 'sets outcome to nil' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id][:outcome]).to be_nil
    end

    it 'sets resolved_at to nil' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id][:resolved_at]).to be_nil
    end

    it 'initializes exchanges to an empty array' do
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id][:exchanges]).to eq([])
    end

    it 'sets created_at to a recent UTC time' do
      before = Time.now.utc
      id = log.record(parties: parties, severity: severity, description: description)
      expect(log.conflicts[id][:created_at]).to be >= before
    end

    it 'auto-assigns posture via recommended_posture when no posture given' do
      id = log.record(parties: parties, severity: :critical, description: description)
      expect(log.conflicts[id][:posture]).to eq(:stubborn_presence)
    end

    it 'uses the provided posture when explicitly passed' do
      id = log.record(parties: parties, severity: :low, description: description, posture: :persistent_engagement)
      expect(log.conflicts[id][:posture]).to eq(:persistent_engagement)
    end

    it 'each call returns a unique id' do
      id1 = log.record(parties: parties, severity: :low, description: 'a')
      id2 = log.record(parties: parties, severity: :low, description: 'b')
      expect(id1).not_to eq(id2)
    end
  end

  describe '#add_exchange' do
    let!(:conflict_id) { log.record(parties: parties, severity: severity, description: description) }

    it 'appends to the exchanges array' do
      log.add_exchange(conflict_id, speaker: 'agent', message: 'I object')
      expect(log.conflicts[conflict_id][:exchanges].size).to eq(1)
    end

    it 'stores the speaker' do
      log.add_exchange(conflict_id, speaker: 'human', message: 'proceed anyway')
      exchange = log.conflicts[conflict_id][:exchanges].last
      expect(exchange[:speaker]).to eq('human')
    end

    it 'stores the message' do
      log.add_exchange(conflict_id, speaker: 'agent', message: 'I strongly disagree')
      exchange = log.conflicts[conflict_id][:exchanges].last
      expect(exchange[:message]).to eq('I strongly disagree')
    end

    it 'sets :at to a recent UTC time' do
      before = Time.now.utc
      log.add_exchange(conflict_id, speaker: 'agent', message: 'noted')
      exchange = log.conflicts[conflict_id][:exchanges].last
      expect(exchange[:at]).to be >= before
    end

    it 'supports multiple sequential exchanges' do
      log.add_exchange(conflict_id, speaker: 'agent', message: 'message 1')
      log.add_exchange(conflict_id, speaker: 'human', message: 'message 2')
      log.add_exchange(conflict_id, speaker: 'agent', message: 'message 3')
      expect(log.conflicts[conflict_id][:exchanges].size).to eq(3)
    end

    it 'returns nil for a non-existent conflict_id' do
      result = log.add_exchange('no-such-id', speaker: 'agent', message: 'hello')
      expect(result).to be_nil
    end

    it 'does not modify exchanges when conflict_id is missing' do
      log.add_exchange('ghost-id', speaker: 'x', message: 'y')
      expect(log.conflicts.values.flat_map { |c| c[:exchanges] }).to be_empty
    end
  end

  describe '#resolve' do
    let!(:conflict_id) { log.record(parties: parties, severity: severity, description: description) }

    it 'returns the updated conflict hash' do
      result = log.resolve(conflict_id, outcome: :compromise)
      expect(result).to be_a(Hash)
      expect(result[:conflict_id]).to eq(conflict_id)
    end

    it 'sets status to :resolved' do
      log.resolve(conflict_id, outcome: :compromise)
      expect(log.conflicts[conflict_id][:status]).to eq(:resolved)
    end

    it 'stores the outcome' do
      log.resolve(conflict_id, outcome: :agreement)
      expect(log.conflicts[conflict_id][:outcome]).to eq(:agreement)
    end

    it 'sets resolved_at to a recent UTC time' do
      before = Time.now.utc
      log.resolve(conflict_id, outcome: :withdrawn)
      expect(log.conflicts[conflict_id][:resolved_at]).to be >= before
    end

    it 'stores resolution_notes when provided' do
      log.resolve(conflict_id, outcome: :compromise, resolution_notes: 'both parties agreed to defer')
      expect(log.conflicts[conflict_id][:resolution_notes]).to eq('both parties agreed to defer')
    end

    it 'stores nil resolution_notes when not provided' do
      log.resolve(conflict_id, outcome: :compromise)
      expect(log.conflicts[conflict_id][:resolution_notes]).to be_nil
    end

    it 'returns nil for a non-existent conflict_id' do
      result = log.resolve('ghost-id', outcome: :compromise)
      expect(result).to be_nil
    end
  end

  describe '#active_conflicts' do
    it 'returns empty array when no conflicts exist' do
      expect(log.active_conflicts).to be_empty
    end

    it 'returns all unresolved conflicts' do
      3.times { log.record(parties: parties, severity: :low, description: 'test') }
      expect(log.active_conflicts.size).to eq(3)
    end

    it 'excludes resolved conflicts' do
      id = log.record(parties: parties, severity: :low, description: 'resolved one')
      log.record(parties: parties, severity: :high, description: 'still active')
      log.resolve(id, outcome: :withdrawn)
      expect(log.active_conflicts.size).to eq(1)
    end

    it 'returns conflict hashes with status :active' do
      log.record(parties: parties, severity: :medium, description: 'check status')
      log.active_conflicts.each do |conflict|
        expect(conflict[:status]).to eq(:active)
      end
    end
  end

  describe '#get' do
    it 'returns the conflict hash for a known id' do
      id = log.record(parties: parties, severity: severity, description: description)
      result = log.get(id)
      expect(result[:conflict_id]).to eq(id)
    end

    it 'returns nil for an unknown id' do
      expect(log.get('missing-id')).to be_nil
    end
  end

  describe '#count' do
    it 'returns 0 for a new log' do
      expect(log.count).to eq(0)
    end

    it 'returns the total number of recorded conflicts' do
      3.times { log.record(parties: parties, severity: :low, description: 'x') }
      expect(log.count).to eq(3)
    end

    it 'counts resolved conflicts as well as active ones' do
      id = log.record(parties: parties, severity: :low, description: 'resolve me')
      log.resolve(id, outcome: :agreement)
      log.record(parties: parties, severity: :high, description: 'still active')
      expect(log.count).to eq(2)
    end
  end
end
