#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "..")

require "snweb/sninternal"

count = 0

csv = File.open("grad-year.csv").read.split("\n").map { |record| record.split(",") }
csv.each do |name, year|
  year = year.to_i
  if name.start_with?("Mr")
    name = name.gsub(/^Mr /, "")
  elsif name.start_with?("Dr")
    name = name.gsub(/^Dr /, "")
  end
  name_parts = Array.new
  name.split.each do |part|
    name_parts << part.chomp if part.length > 2
  end
  ds = SNweb::DB[:brothers]
  name_parts.each do |part|
    ds = ds.filter(:name.ilike("%" + part + "%"))
    break if ds.count == 1
  end
  if ds.count == 1
    ds.update(:class => year)
  else
    # try going backward
    ds = SNweb::DB[:brothers]
    name_parts.reverse.each do |part|
      ds = ds.filter(:name.ilike("%" + part + "%"))
      break if ds.count == 1
    end
    if ds.count == 1
      ds.update(:class => year)
    else
      puts name, year
      count += 1
    end
  end
end

puts count
