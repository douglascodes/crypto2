require 'net/http'
require 'rexml/document'
require 'action_view'
require 'date'
require 'pry'
require 'radix'
include REXML
include ActionView::Helpers::SanitizeHelper

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

include Unique

class Solver   #The problem solver class. Gets puzzles, parses em, Solves em. Saves em.
  attr_accessor :p_list, :solved, :let_list, :dicts, :dicts_big, :pop_dict
  def initialize
    @p_list = get_puzzles() #List of puzzle objects
    @solved = 0             #Simple enumerator for number of solved puzzles
    @dicts = set_dicts(@dicts, './data/xresultant.txt')
    @pop_dict = set_popular()
  end

  def get_puzzles
    #Loads puzzles for the solver class to work on
    f = REXML::Document.new(get_feed())
    r = f.root
    return conform_puzzles(r)
  end

  def get_feed(xmlfeed='http://www.threadbender.com/rss.xml')
    #Downloads an XML feed. The default is the test one.
      feed = URI(xmlfeed)
      feed = Net::HTTP.get(feed)
      return feed
  end

  def set_dicts(dicts, source='./data/xresultant.txt')
    words = []
    add_to_word_list(words, source)
    dicts = Array.new(20)
    words.each { |w|
      w.chomp!
      w.upcase!
      add_word(w, dicts)
    }
    return dicts
  end

  def set_popular(source='./data/top10k.txt')
    words = []
    add_to_word_list(words, source)
    dicts = Array.new(20)
    words.each { |w|
      w.chomp!
      w.upcase!
      add_word(w, dicts)
    }
    return dicts
  end

  def add_to_word_list(w_array, file)
    f = IO.readlines(file)
    w_array.concat(f)
  end

  def add_word(w, dicts)
       #Removes the roman numerals starting with X. Not needed
      dicts[w.length] ||= Hash.new
      if dicts[w.length].has_key?(w) then return end
      dicts[w.length].merge!({w => unique_ify(w).length})
  end

  def conform_puzzles(root)
    #Strips XML tags and creates a list of Puzzle objects
    p_list = Array.new
    root.each_element('//item') { |item|
      desc, author, date = break_up_puzzle(item)  #Seperates the extracted puzzle into three parts
      p_list << Puzzle.new(desc, author, date)
    }
    return p_list
  end

  def break_up_puzzle(p)
    desc = p.delete_element('description').to_s
    desc = strip_tags(desc)
    desc, author = seperate_author(desc)
    date = p.delete_element('pubDate').to_s
    date = Date.parse(strip_tags(date))
    return desc, author, date
  end

  def seperate_author(unbroken)
    #Sets puzzle to unsolved letters (downcase) and removes punctuation
    unbroken.downcase!
    a, b = unbroken.split(/[.?!]"* - /)
    # Special thanks to RUBULAR.com
    # Breaks the puzzle at the Crypto/Author break. Author starts with" -"
    # Sentence ends with punctuation. So "! -", ". -", '?" -' all must be accounted
    a.delete!(".,!?:;&()")
    a.strip!
    b.delete!(".,!?:;&()")
    b.strip!
    return a, b
  end

  def go_to_work(which=nil)
    #takes the passed argument from main.rb
      if which
        p = @p_list[which]
         solve(p)
         create_solution(p)
         puts p.solution
      else
        @p_list.each { |p|
         solve(p)
         create_solution(p)
         p.set_solve_date
         puts p.solution
      }
      end
  end

  def create_solution(puzz)
    mask = %w[ E T A O I N S H R D L C U M W F G Y P B V K J X Q Z ' -]
    puzz.solution = (puzz.crypto << ' - ' << puzz.author)
    @let_list.each { |k, v|
      if v.possible.frozen? then next end
      if v.possible.empty? then next end
      priority = v.possible.take_while{ |p|
        mask.include? p
      }
      puzz.solution.gsub!(k, priority.first)
    }
  end

  def solve(puzz)
    c = puzz.crypto_broken
    c.map! {|x| x = Word.new(x,@dicts)}
    set_letters()
    for z in 1..3
      for x in 1..c[-1].length
      c.each { |word|
        if word.u_length > x then next end
        if word.possibles.length > 0 
          reverse_lookup(word)
          condense_true(word.uniques, word.possibles)           
        end
        }
      end
    end
  end

  def reverse_lookup(word)
    word.possibles.keep_if { |x|
      char_matcher(word.name, x)
    }
    # puts word.possibles
  end

  def char_matcher(w, p)
    counter = w.length-1
    for x in 0..counter
      if @let_list[w[x]].possible.include?(p[x]) then next end
      return false
    end
    return true
  end

  def condense_true(key, p_words)
    #For creating an array for each unique letter containing one of each possibility
    #the possible letters will shrink each time a word is tested. Till all contain just one
    #possiblity... or hilarity will ensue in having a cryptogram with an alternate possibility
    words = p_words.map { |w| unique_ify(w) }

    for position in 0..key.length-1
      letter = @let_list[key[position]]
      if letter.possible.frozen? then next end
      letter.possible.clear
      words.each { |word|
        if letter.possible.include?(word[position]) then next end
        letter.possible << word[position]
      }
    end
  end

  def set_letters()
    #Creates an alphabetical list of LETTER objects
    @let_list = Hash.new
      for l in "a".."z"
        @let_list.merge!({l => Letter.new(l)})
      end
    @let_list.merge!({'\'' => Letter.new('\'')})
    @let_list.merge!({'-' => Letter.new('-')})
  end

end

class Puzzle
  attr_accessor :crypto, :crypto_broken, :solution, :author_sol, :author, :publ_date, :solve_time,
    :uniques, :full_uniques
  def initialize(crypto='ABCDEF', author="Bace Troncons", publ_date=Time.now)
    @crypto = crypto          #The seperated cryptogram from the author section
    @author = author          #The seperated author section for the crpytogram
    @publ_date = publ_date    #The seperated date value
    @solve_time = nil         #Var for the date/time the solution was first made
    @uniques = unique_ify(@crypto)
    @full_uniques = unique_ify((@crypto + @author))
    set_up_puzzle()
  end

  def set_solve_date
    if @solve_time
      return
    end
    @solve_time = Time.now
  end

  def set_up_puzzle()
    #Breaks PUZZ into the crypto array sorted by word size
    @crypto_broken = Set.new
    @crypto_broken += @crypto.split
    hyphens = Array.new
    @crypto_broken.each { |w|
       if w.include? '-' then hyphens += w.split(/-/) end
     }
    @crypto_broken.delete_if { |w|
      w.include? '-'
    }
    @crypto_broken += hyphens
    @crypto_broken = @crypto_broken.each.sort { |a,b|  #Sorts words by size
    unique_ify(a).length <=> unique_ify(b).length
  }
  end

  def to_s
    print 'Code: ', @crypto,  "\nDate: ", @publ_date, "\nCompleted: ", @solve_time, "\n"
  end
end

class Letter
  #Letter objects that contain their own NAME, and a list of POSSIBLE interpretations
  #It is assumed that by the rules of the cryptogram that they cannot end up being themself
  attr_accessor :name, :possible

  def initialize(itself="r")
    #Sets the possible list, and the self.name
    #lowercase letters are the unchanged letters, upcase is solved letters
    if itself == "'" || itself == '-'
      @name = itself
      @possible = Set[itself]
      @possible.freeze
    else
      @name = itself.downcase
      @possible = Set.new
      @possible = %w[ E T A O I N S H R D L C U M W F G Y P B V K J X Q Z ]
      @possible.delete(itself.upcase)
    end
  end

end

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