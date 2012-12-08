class Word
  attr_accessor :name, :uniques, :u_length, :length, :possibles, :pattern_value

  def initialize(name="test", dictionary)
    @name = name
    @uniques = unique_ify(name)
    @length = @name.length
    @u_length = @uniques.length
    @pattern_value = pattern_check(name)
    @possibles = find_possibles(dictionary)
  end

  def find_possibles(dictionary)
    p = Array.new
    
    dictionary[@length].each { |k, v|
      if k.length == @length && v == @u_length  #&& @pattern_value == pattern_check(k)
        p << k

      end
    }
    p.keep_if { |x| 
      pattern_check(x) == @pattern_value
    }
    return p
  end

end