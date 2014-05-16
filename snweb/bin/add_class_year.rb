#!/usr/bin/env ruby
# encoding: utf-8

require "nokogiri"
require "sequel"

# import old db
f = File.open("internal.xml")
internal = Nokogiri::XML(f)
f.close

# pump it into the DB
DB = Sequel.connect('sqlite://sn.db')

# munge the datas
internal.xpath("//database/table_data[@name='Brothers']/row").each do |brother|
  pin_raw = brother.xpath("field[@name='InitNumber']")
  class_raw = brother.xpath("field[@name='ClassYear']")

  pin = pin_raw ? pin_raw.text.to_i: nil
  class_year = class_raw.text.empty? ? nil : class_raw.text.to_i

  DB[:brothers].filter(:pin => pin).update({ :class => class_year })
end

