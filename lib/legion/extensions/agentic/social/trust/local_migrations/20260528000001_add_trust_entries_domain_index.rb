# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:trust_entries) do
      add_index :domain, name: :idx_trust_entries_domain
    end
  end

  down do
    alter_table(:trust_entries) do
      drop_index :domain, name: :idx_trust_entries_domain
    end
  end
end
