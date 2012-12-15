require 'net/http'
require 'rexml/document'
require 'action_view'
require 'date'
require 'pry'
require './lib/unique'
require './lib/word'
require './lib/letter'
require './lib/puzzle'
# require 'puzzle'
include Unique
include REXML
include ActionView::Helpers::SanitizeHelper

class Solver   #The problem solver class. Gets puzzles, parses em, Solves em. Saves em.
  attr_accessor :p_list, :solved, :let_list, :dicts, :name_dict, :pop_dict, :dict_1k
  def initialize
    @p_list = get_puzzles() #List of puzzle objects
    @solved = 0             #Simple enumerator for number of solved puzzles
    @dicts = set_dicts(@dicts, './data/xresultant.txt')
    @pop_dict = set_dicts(@pop_dict, './data/top10k.txt')
    @name_dict = set_dicts(@name_dict, './data/SMITH.txt')
    @dict_1k = set_dicts(@dict_1k, './data/top_1000.txt')
  end 

  def get_puzzles
    #Loads puzzles for the solver class to work on
    # f = REXML::Document.new(get_feed())
    f = REXML::Document.new(File.open('./data/test.xml'))
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
    dicts = Array.new(28)
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
         binding.pry
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
    solve_with_whole_words(puzz)
    solve_with_letters(puzz)
  end

  def solve_with_whole_words(puzz)
    puzz.solution = (' ' << puzz.crypto << ' - ' << puzz.author << ' ')
    puzz.full_broken.reverse!    
    puzz.full_broken.each {|word|
      if word.possibles.length < 1 then next end
      puzz.solution.gsub!('-'+word.name+' ', '-'+word.possibles.first.to_s+' ')      
      puzz.solution.gsub!(' '+word.name+'-', ' '+word.possibles.first.to_s+'-')      
      puzz.solution.gsub!(' '+word.name+' ', ' '+word.possibles.first.to_s+' ')      
    }
    puzz.solution.strip!
  end
  
  def solve_with_letters(puzz)
    mask = %w[ E T A O I N S H R D L C U M W F G Y P B V K J X Q Z ' -]
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
    a = puzz.author_broken
    c.map! {|x| 
      # r = Word.new(x,@pop_dict)
      # if r.possibles == nil then r = Word.new(r.name, @dicts) end
         # x = r
      x = Word.new(x, @dicts)
    }

    a.map! {|x| 
      x = Word.new(x, @name_dict)
    }

    a.each { |x|
      #Allows single letters in the author section to be any standard initial. "I M Pei" for ex.
      if x.length == 1 then x.possibles = *('A'..'Z') end
    }

    c += a
    
    # Now that the author section and crypto section have word objects with each's own dictionary
    # we can work on them in the same way.

    set_letters(puzz.full_uniques)
    
    for z in 1..5
    
      for x in 1..c[-1].length
      c.each { |word|
        work_the_word(x, word)
        }
      end
      
      if z >= 3
        kill_singles()
        c.each { |word|
          if word.possibles.length > 0 then reverse_lookup(word) end
          }
      end
    
      if z >= 4
        run_smaller_dictionaries(c)
      end
    end
    puzz.full_broken = c
    puzz.let_list = @let_list
  end

  def run_smaller_dictionaries(broken)
    broken.each { |word| 
      if word.possibles.length < 2 then next end 
    }
  end

  def kill_singles()
    singulars = Set.new
    
    @let_list.each_value { |l|
      if l.possible.frozen? then next end
      if l.possible.length == 1 then singulars << l.possible.first end
    }

  singulars.each { |s|
    @let_list.each_value { |l|
      if l.possible.length == 1 then next end
      if l.possible.include? s then l.possible.delete(s) end
    }
  }


  end

  def work_the_word(x, word)
    if word.u_length > x then return end
      if word.possibles.length > 0 
        reverse_lookup(word)
        if word.possibles.length > 0 then condense_true(word.uniques, word.possibles) end
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

  def poss(word, dict)
    if dict[word.length].key?(word) then return true end
    return false
  end

  def set_letters(salt)
    #Creates an alphabetical list of LETTER objects
    @let_list = Hash.new
    salt.chars { |l| 
        @let_list.merge!({l => Letter.new(l)})
    }      
    # @let_list.merge!({'\'' => Letter.new('\'')})
    # @let_list.merge!({'-' => Letter.new('-')})
  end
end