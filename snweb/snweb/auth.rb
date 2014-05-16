require "digest/sha1"

module SNweb
  class Auth
    def self.random_string(len)
      #generate a random password consisting of strings and digits
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      newpass = ""
      len.times do
        newpass << chars[rand(chars.size-1)]
      end
      newpass
    end

    def self.encrypt(pass, salt)
      Digest::SHA1.hexdigest("#{pass}#{salt}")
    end
  end
end

