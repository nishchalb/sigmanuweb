Sequel.migration do
  change do
    alter_table :brothers do
      add_unique_constraint :nickname
    end
  end
end

