#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "..")

require "snweb/sninternal"

SNweb::DB[:brothers].filter('pin > ?', 643).each do |bro|
  # add auth with default pass = honor1869
  salt = SNweb::Auth.random_string(15)
  encrypted = SNweb::Auth.encrypt(SNweb::SNInternalServer::DEFAULT_PASS, salt)
  SNweb::DB[:auth].insert({ hash: encrypted, salt: salt, username: bro[:email],
                     pin: bro[:pin] })
end
