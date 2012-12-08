module Unique
  def unique_ify(word)
    if word.length < 2 then return word end 
    u = ''
    word.each_char { |c|
    if u.include? c then next end
      u << c
    }
    return u
  end

  def pattern_check(string)
    s = string.split("")
    h = Hash.new
    s.map! { |x| Base64.encode64(x)}
    counter = 0.b(256)
    s.each { |x|
      if h.key?(x)
        next
      else
        h.merge!({x => counter})
        counter += 1
      end
    }
    s.map! { |x| x = h[x] }
    return s
  end
end