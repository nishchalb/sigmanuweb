Sequel.migration do
  change do
    alter_table :brothers do
      drop_constraint :nickname, :type => :unique
    end
  end
end

