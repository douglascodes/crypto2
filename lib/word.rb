class Word
  attr_accessor :name, :uniques, :u_length, :length, :possibles, :pattern_value, :current_dict

  def initialize(name="test", dictionary)
    @name = name
    @uniques = unique_ify(name)
    @length = @name.length
    @u_length = @uniques.length
    @pattern_value = pattern_create(name)
    @possibles = find_possibles(dictionary)
    @current_dict = dictionary
  end

  def which_dictionary?
    return @current_dict[0]
  end

  def has_possibilities?
    if @possibles.length < 1 then return false end
    return true
  end

  def find_possibles(dictionary)
    p = Array.new
    if dictionary[@length]
      dictionary[@length].each { |k, v|
        if k.length == @length && v == @u_length  #&& @pattern_value == pattern_create(k)
          p << k

        end
      }
      p.keep_if { |x| 
        pattern_create(x) == @pattern_value
      }
      return p
    end
  end

end