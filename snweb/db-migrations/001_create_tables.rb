Sequel.migration do
  up do
    create_table :brothers do
      primary_key :id
      Integer :pin, :unique => true
      String  :name
      Boolean :active
      Boolean :expelled
      Integer :pledge_class_id
      String  :nickname
      String  :phone
      String  :email
      String  :class
      String  :major
    end

    create_table :pledge_classes do
      primary_key :id
      String :name
    end

    create_table :big_to_little do
      Integer :big_id
      Integer :little_id
    end

    create_table :officers do
      Integer :pin
      Integer :office_id
      Integer :term
    end

    create_table :offices do
      primary_key :id
      String :title
      Boolean :elect_in_spring
      Boolean :elect_in_fall
      Boolean :appointed
    end
  end

  down do
    drop_table(:brothers)
    drop_table(:pledge_classes)
    drop_table(:big_to_little)
    drop_table(:officers)
    drop_table(:offices)
  end
end

