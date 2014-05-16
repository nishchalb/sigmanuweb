# encoding: utf-8

# adapted from http://ididitmyway.heroku.com/past/2010/5/31/partials/
def partial(template, locals=nil)
  locals = locals.is_a?(Hash) ? locals : { template.to_sym =>  locals }
  locals[:styles] ||= Array.new
  locals[:scripts] ||= Array.new
  template = ('_' + template.to_s).to_sym
  erb(template, { :layout => false }, locals)
end

def has_variable? var
  defined? var
end

def slugify bro
  return nil if bro.nil?
  bro_num = 0
  index = 0
  SNweb::DB[:brothers].filter(:name => bro[:name]).each do |b|
    bro_num = index if bro[:pin] == b[:pin]
    index += 1
  end
  if bro_num == 0
    "#{bro[:name]}".split.join("-").downcase
  else
    "#{bro[:name]} #{bro_num}".split.join("-").downcase
  end
end

def get_bro_from_slug(slug)
  bro_to_take = 0
  slug_pieces = slug.split("-")
  if /^\d+$/ =~ slug_pieces[-1]
    bro_to_take = slug_pieces[-1].to_i
    slug_pieces.pop
  end
  name = slug_pieces.join("%")

  @bro = nil
  if bro_to_take == 0
    @bro = SNweb::DB[:brothers].filter(:name.ilike(name)).first
  else
    i = 0
    SNweb::DB[:brothers].filter(:name.ilike(name)).each do |b|
      @bro = b if i == bro_to_take
      i += 1
    end
  end
end


def photo bro
  Dir.glob(File.join("snweb", "public", "photos", "bropics", "*")).each do |f|
    f = f.split("/")
    f.shift
    f.shift
    f = "/" + f.join("/")
    return f if /\/photos\/bropics\/#{slugify(bro)}\./ =~ f
  end
  return nil
end

def get_next_pledge_class pledge_class
  parts = pledge_class.split("")
  parts_reversed = parts.reverse
  num_to_greek = {
    0  => 'Α',
    1  => 'Β',
    2  => 'Γ',
    3  => 'Δ',
    4  => 'Ε',
    5  => 'Ζ',
    6  => 'Η',
    7  => 'Θ',
    8  => 'Ι',
    9  => 'Κ',
    10 => 'Λ',
    11 => 'Μ',
    12 => 'Ν',
    13 => 'Ξ',
    14 => 'Ο',
    15 => 'Π',
    16 => 'Ρ',
    17 => 'Σ',
    18 => 'Τ',
    19 => 'Υ',
    20 => 'Φ',
    21 => 'Χ',
    22 => 'Ψ'
  }
  greek_to_num = {}
  num_to_greek.each_pair do |k,v|
    greek_to_num[v] = k
  end
  modulus = num_to_greek.keys.length
  parts_reversed.each_index do |index|
    part = parts_reversed[index]
    puts part
    parts_reversed[index] = num_to_greek[(greek_to_num[part] + 1) % modulus]
    return parts_reversed.reverse.join("") if parts_reversed[index] != num_to_greek[0]
  end
end

def public_photo section
  Dir.glob(File.join("snweb", "public", "photos", "public", "*")).each do |f|
    f = f.split("/")
    f.shift
    f.shift
    f = "/" + f.join("/")
    return f if /\/photos\/public\/#{section}\./ =~ f
  end
  return nil
end

