#!/usr/bin/env ruby
# encoding: utf-8

require "nokogiri"
require "sequel"

# import old db
f = File.open("internal.xml")
internal = Nokogiri::XML(f)
f.close

spelled_to_greek = {
  'alpha' => 'Α',
  'beta' => 'Β',
  'gamma' => 'Γ',
  'delta' => 'Δ',
  'epsilon' => 'Ε',
  'zeta' => 'Ζ',
  'eta' => 'Η',
  'theta' => 'Θ',
  'iota' => 'Ι',
  'kappa' => 'Κ',
  'lambda' => 'Λ',
  'mu' => 'Μ',
  'nu' => 'Ν',
  'xi' => 'Ξ',
  'omicron' => 'Ο',
  'pi' => 'Π',
  'rho' => 'Ρ',
  'sigma' => 'Σ',
  'tau' => 'Τ',
  'upsilon' => 'Υ',
  'phi' => 'Φ',
  'chi' => 'Χ',
  'psi' => 'Ψ',
  'omega' => 'Ω'
}

brother_info = {}
big_to_little = {}
pledge_classes = []
nicknames = {}

# munge the datas
internal.xpath("//database/table_data[@name='Brothers']/row").each do |brother|
  pin_raw = brother.xpath("field[@name='InitNumber']")
  littles_raw = brother.xpath("field[@name='LittleBros']")
  first_raw = brother.xpath("field[@name='FirstName']")
  last_raw = brother.xpath("field[@name='LastName']")
  expelled_raw = brother.xpath("field[@name='Expelled']")
  active_raw = brother.xpath("field[@name='Active']")
  nickname_raw = brother.xpath("field[@name='Nickname']")
  pledge_class_raw = brother.xpath("field[@name='PledgeClass']")
  email_raw = brother.xpath("field[@name='MITEmail']")

  pledge_classes << pledge_class_raw.text.strip

  name = first_raw.text.strip + " " + last_raw.text.strip
  expelled = expelled_raw.text == "No" ? false : true
  active = active_raw.text == "No" ? false : true

  pin = pin_raw ? pin_raw.text.to_i: nil
  littles = littles_raw ? littles_raw.text.strip.split.map { |id| id.to_i } : nil
  big_to_little[pin] = littles

  brother_info[pin] = { name: name, expelled: expelled, active: active, nickname: nickname_raw.text, email: email_raw.text }
end

def greekify pledge_class, greek_map
  words = pledge_class.split
  new_words = []
  words.each do |word|
    new_words << greek_map[word.downcase]
  end
  new_words.join("")
end

# do pledge class id assigning
# uniqify list and convert to greek
pledge_classes = pledge_classes.uniq.map do |pc|
  greekify(pc, spelled_to_greek)
end.sort
# make bro to pc mapping
internal.xpath("//database/table_data[@name='Brothers']/row").each do |brother|
  pin_raw = brother.xpath("field[@name='InitNumber']")
  pledge_class_raw = brother.xpath("field[@name='PledgeClass']")

  pin = pin_raw ? pin_raw.text.to_i: nil
  pledge_class_id = pledge_classes.index(greekify(pledge_class_raw.text.strip, spelled_to_greek)) + 1
  brother_info[pin][:pledge_class_id] = pledge_class_id
end

# pump it into the DB
DB = Sequel.connect('sqlite://sn.db')

brother_info.sort_by { |pin, info| pin }.each do |pin, info|
  info = info.merge pin: pin
  DB[:brothers].insert info
end

# housekeeping
DB[:brothers].filter((:pin + 1) < (644 + 1)).filter(~{ :pin => 639 }).update(:active => false)

pledge_classes.each do |pc|
  DB[:pledge_classes].insert name: pc
end

big_to_little.sort_by { |big, little| big }.each do |big, littles|
  big_id = DB[:brothers].filter(:pin => big).first[:id]
  littles.each do |little|
    little_id = DB[:brothers].filter(:pin => little).first[:id]
    DB[:big_to_little].insert big_id: big_id, little_id: little_id
  end
end

nicknames.sort_by { |pin, info| pin }.each do |pin, info|
  DB[:nicknames].insert pin: pin, nickname: info
end

# time for the 'not easily parseable' stuff
# Family line roots
DB[:family_lines].insert root: DB[:brothers].filter(:pin => 512).first[:id], name: "Crowe Line"
DB[:family_lines].insert root: DB[:brothers].filter(:pin => 515).first[:id], name: "Ko Line"
DB[:family_lines].insert root: DB[:brothers].filter(:pin => 517).first[:id], name: "Wertheim Line"
DB[:family_lines].insert root: DB[:brothers].filter(:pin => 592).first[:id], name: "Alpha Line"
DB[:family_lines].insert root: DB[:brothers].filter(:pin => 514).first[:id], name: "The Cartel"
DB[:family_lines].insert root: DB[:brothers].filter(:pin => 593).first[:id], name: "Yang Line"
DB[:family_lines].insert root: DB[:brothers].filter(:pin => 513).first[:id], name: nil
DB[:family_lines].insert root: DB[:brothers].filter(:pin => 516).first[:id], name: nil

# offices
DB[:offices].insert title: "Commander", elect_in_spring: false, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Lieutenant Commander", elect_in_spring: true, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Treasurer", elect_in_spring: false, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Recorder", elect_in_spring: true, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Marshal", elect_in_spring: false, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Rush Chair", elect_in_spring: true, elect_in_fall: false, appointed: false
DB[:offices].insert title: "Rush Chair", elect_in_spring: false, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Community Service Chair", elect_in_spring: true, elect_in_fall: true, appointed: false
DB[:offices].insert title: "House Manager", elect_in_spring: true, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Social Chair", elect_in_spring: false, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Chaplain", elect_in_spring: true, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Steward", elect_in_spring: true, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Scholarship Chair", elect_in_spring: true, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Webmaster", elect_in_spring: true, elect_in_fall: true, appointed: false
DB[:offices].insert title: "Risk Reduction", elect_in_spring: true, elect_in_fall: true, appointed: false

