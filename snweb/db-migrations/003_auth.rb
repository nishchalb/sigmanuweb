Sequel.migration do
  change do
    create_table :auth do
      Integer :pin
      String :username, :unique => true
      String :hash
      String :salt
    end
  end
end

