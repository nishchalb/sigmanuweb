#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "..")

require "snweb/sninternal"
require "snweb/helpers"

Dir.entries("old-bropics/brothers/").each do |f|
  next if f == "." || f == ".."
  next if !(/^\d+\./ =~ f)
  pin = f.split('.')[0].to_i
  bro = SNweb::DB[:brothers].filter(:pin => pin).first
  out_name = "#{slugify(bro)}.#{f.split(".")[1]}"
  %x[cp "old-bropics/brothers/#{f}" "snweb/public/photos/bropics/#{out_name}"]
end

