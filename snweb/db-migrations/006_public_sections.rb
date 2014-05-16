Sequel.migration do
  change do
    create_table :sections do
      primary_key :id
      String :title, :unique => true
      String :text
    end
  end
end

