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
    @current_dict[0]
  end

  def has_possibilities?
#    return false if @possibles == nil
    @possibles.length > 0
  end

  def reload_possibles
    @possibles = find_possibles(@current_dict)
  end

=begin
  def find_possibles(dictionary)
    p = Array.new
    if dictionary[@length]
      dictionary[@length].each { |k, v|
        if k.length == @length && v == @u_length && @pattern_value == pattern_create(k)
          p << k
        end
      }
      return p
    end
  end
=end

  def find_possibles(dictionary)
    return [] if dictionary[@length] == nil
    p = dictionary[@length].dup
    p.keep_if { |k, v|
        k.length == @length && v == @u_length && @pattern_value == pattern_create(k)
        }
    p.keys
  end

end