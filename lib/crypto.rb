require  'net/http'
require  'rexml/document'
require  'action_view'
require  'date'
require  'pry'
require  './lib/unique'
require  './lib/word'
require  './lib/letter'
require  './lib/puzzle'
# require 'puzzle'
include Unique
include REXML
include ActionView::Helpers::SanitizeHelper

class Solver   #The problem solver class. Gets puzzles, parses em, Solves em. Saves em.
  attr_accessor :p_list, :solved, :let_list, :dicts, :name_dict, :pop_dict, :dict_1k
  def initialize
    @p_list = get_puzzles() #List of puzzle objects
    @solved = 0             #Simple enumerator for number of solved puzzles
    @dicts = set_dicts(@dicts, './data/xresultant.txt', "Fullsize Dictionary")
    @pop_dict = set_dicts(@pop_dict, './data/top10k.txt', "Top 10,000 Words")
    @name_dict = set_dicts(@name_dict, './data/SMITH.txt', "Proper Names Dictionary")
    @dict_1k = set_dicts(@dict_1k, './data/top_1000.txt', "Pimsleur top 1k")
  end 

  def get_puzzles
    #Loads puzzles for the solver class to work on
    # r = (REXML::Document.new(get_feed())).root
    d = (REXML::Document.new(File.open('./data/test.xml')))
    return conform_puzzles(d)
  end

  def get_feed(xmlfeed='http://www.threadbender.com/rss.xml')
    #Downloads an XML feed. The default is the test one.
    return Net::HTTP.get(URI(xmlfeed))
  end

  def set_dicts(dicts, source='./data/xresultant.txt', dict_name="Test Dictionary")
    words = Array.new
    add_to_word_list(words, source)
    dicts = Array.new(28)
    words.each { |w|
      w.strip!
      w.upcase!
      add_word(w, dicts)
    }
    dicts[0] = dict_name
    return dicts
  end

  def add_to_word_list(w_array, file)
    w_array.concat(IO.readlines(file))
  end

  def add_word(w, dicts)
      #Removes the roman numerals starting with X. Not needed
      dicts[w.length] ||= Hash.new
      if dicts[w.length].has_key?(w) then return end
      dicts[w.length].merge!({w => unique_ify(w).length})
  end

  def conform_puzzles(doc)
    #Strips XML tags and creates a list of Puzzle objects
    p_list = Array.new
    doc.each_element("//item") { |e| 
      date = author = desc = nil
      date = Date.parse(strip_tags(e.elements['pubDate'].to_s))
      desc, author = seperate_author(strip_tags(e.elements['description'].to_s))
        if desc && author && date
          p_list << Puzzle.new(desc, author, date)
        end
    }
    return p_list
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
         puts p.crypto + ' - '+ p.author         
         puts p.solution
         binding.pry
      else
        @p_list.each { |p|
         solve(p)
         create_solution(p)
         p.set_solve_date
         puts p.crypto + ' - '+ p.author         
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
    # puzz.full_broken.reverse!    
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

  def setup_solve(puzz)
    c = puzz.crypto_broken
    a = puzz.author_broken
    c.map! {|x| x = Word.new(x, @dicts)}

    c.each {|x| 
      if x.possibles.length > 0 then next end
      x = Word.new(x.name, @name_dict)
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
    return c
  end

  def solve(puzz)
    c = setup_solve(puzz)

    for z in 1..6
    
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
    
      if z == 3
        run_smaller_dictionaries(c - puzz.author_broken, @pop_dict)
      end
      if z == 4
        run_smaller_dictionaries(c - puzz.author_broken, @dict_1k)
      end
    end
    puzz.full_broken = c
    puzz.let_list = @let_list
  end

  def run_smaller_dictionaries(broken, dict)
    broken.each { |word| 
      if word.possibles.length < 2 then next end
        word.possibles = try_dictionary(word, dict)
        condense_true(word.uniques, word.possibles)   
    }
  end

  def try_dictionary(w, a)
    p = w.possibles.dup
    w.possibles = w.find_possibles(a)
    reverse_lookup(w)
    if w.possibles.length < 1 then return p end
    condense_true(w.uniques, w.possibles)
    return w.possibles   
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
    # Only keeps the words.possibles if they match the current letter set's possiblities
    word.possibles.keep_if { |x|
      char_matcher(word.name, x)
    }
    # puts word.possibles
  end

  def char_matcher(w, p)
    if w.length != p.length then return false end   #If for some reason the lengths don't match returns FALSE
    counter = w.length-1 #Compensates for the array starting at ZERO
    for x in 0..counter   # Spies across the full length of each word trying to match key letter objects to possbiles
      if @let_list[w[x]].possible.include?(p[x]) then next end  #It IS possbile so continue
      return false #This key letter can't be found in the possible solutions
    end
    return true   # After checking each character we have no failures of match, so it returns TRUE
  end

  def condense_true(key, p_words)
    # Uses the key words unique letters to match against the matching possbilities. Those are reset to 
    # a new possibles list for each letter.
    words = p_words.map { |w| unique_ify(w) }     #Its repetitious to try duplicate characters
                                                  # so we just work with the unique letters
                                                  
    for position in 0..key.length-1         # POSITION is the spot in both words
      letter = @let_list[key[position]]     #retrieves the letter OBJ for that position
      if letter.possible.frozen? then next end # ' AND - are ignored
      letter.possible.clear     # Resets the letter.possible list
      words.each { |word|       # Chunks down on 
        if letter.possible.include?(word[position]) then next end
        letter.possible << word[position] 
      }
    end
  end

  def set_letters(salt)
    # Creates a list of letter objects, and includes apostrophes and hypens.
    # SALT is derived from the unique characters of the puzzle, excluding SPACES
    @let_list = Hash.new    #Sets the empty hash for letter objects
    salt.chars { |l| 
        @let_list.merge!({l => Letter.new(l)})
        # Uses the key_letter (lowercase) for each character as the HASHkey.
        # The value is the letter object created in the Letter.rb file.
    }      
    end
end