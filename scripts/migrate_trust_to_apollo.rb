#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time migration: reads trust entries from the legacy Data::Local SQLite
# trust_entries table and ingests them into Apollo Local, then truncates the table.
#
# Usage:
#   bundle exec ruby scripts/migrate_trust_to_apollo.rb
#
# Prerequisites:
#   - Legion runtime booted (Data::Local connected, Apollo::Local available)
#   - Run BEFORE removing the trust_entries migration from Data::Local

require 'legion'

unless defined?(Legion::Data::Local) && Legion::Data::Local.connected?
  warn '[migrate_trust] Legion::Data::Local is not available or not connected. Aborting.'
  exit 1
end

unless defined?(Legion::Apollo::Local)
  warn '[migrate_trust] Legion::Apollo::Local is not available. Aborting.'
  exit 1
end

dataset = Legion::Data::Local.connection[:trust_entries]
rows = dataset.all

if rows.empty?
  puts '[migrate_trust] No rows in trust_entries table. Nothing to migrate.'
  exit 0
end

puts "[migrate_trust] Found #{rows.size} trust entries to migrate."

migrated = 0
rows.each do |row|
  content = Legion::JSON.dump({
                                agent_id:          row[:agent_id],
                                domain:            row[:domain],
                                dimensions:        {
                                  reliability: row[:reliability].to_f,
                                  competence:  row[:competence].to_f,
                                  integrity:   row[:integrity].to_f,
                                  benevolence: row[:benevolence].to_f
                                },
                                composite:         row[:composite].to_f,
                                interaction_count: row[:interaction_count].to_i,
                                positive_count:    row[:positive_count].to_i,
                                negative_count:    row[:negative_count].to_i,
                                last_interaction:  row[:last_interaction]&.iso8601,
                                created_at:        row[:created_at]&.iso8601
                              })
  tags = ['trust', 'trust_entry', row[:agent_id].to_s, row[:domain].to_s]

  Legion::Apollo::Local.upsert(content: content, tags: tags, source_channel: 'migration', confidence: 0.9)
  migrated += 1
  puts "[migrate_trust] Migrated #{row[:agent_id]}:#{row[:domain]}"
rescue StandardError => e
  warn "[migrate_trust] Failed to migrate #{row[:agent_id]}:#{row[:domain]}: #{e.message}"
end

puts "[migrate_trust] Migrated #{migrated}/#{rows.size} entries."

if migrated == rows.size
  dataset.truncate
  puts '[migrate_trust] Truncated trust_entries table.'
else
  warn '[migrate_trust] Not all entries migrated. Skipping truncate. Re-run after fixing errors.'
end
