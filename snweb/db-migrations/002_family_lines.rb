Sequel.migration do
  change do
    create_table :family_lines do
      Integer :root
      String :name
    end
  end
end

