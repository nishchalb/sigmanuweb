require "sequel"


module SNweb
  # create a module accessor for the global db
  # This method creates the DB when it is invoked only
  # if the DB has not been created before
  def self.datastore
    @datastore ||= Sequel.connect('sqlite://sn.db')
  end

  # This class is a singleton. It defines one method.
  # Its purpose is to allow the db to be accessed by
  # DB[:some_table] as is the sequel convention
  class DB
    def self.[](q)
      SNweb::datastore[q]
    end
  end
end

