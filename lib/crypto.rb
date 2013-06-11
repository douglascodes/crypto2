require  'net/http'
require  'rexml/document'
require  'action_view'
require  'date'
require  'pry'
require  './lib/unique'
require  './lib/word'
require  './lib/dictionary'
require  './lib/letter'
require  './lib/puzzle'
include Unique
include REXML
include ActionView::Helpers::SanitizeHelper

class Solver   #The problem solver class. Gets puzzles, parses em, Solves em. Saves em.
  attr_accessor :puzzle_list, :calculations, :letter_list, :full_dictionary, :proper_name_dictionary, :popular_dictionary, :top_1000_words
  def initialize
    @puzzle_list = get_puzzle_list() #List of puzzle objects
    @calculations = 0             #Simple enumerator for number of calculations puzzles
    @full_dictionary = Dictionary.new("Fullsize Dictionary", './data/xresultant.txt')
    @popular_dictionary = Dictionary.new("Top 10,000 Words",'./data/top10k.txt')
    @proper_name_dictionary = Dictionary.new("Proper Names Dictionary", './data/SMITH.txt')
    @top_1000_words = Dictionary.new("Pimsleur 1000", './data/top_1000.txt')
  end

  def get_puzzle_list
    #Loads puzzles for the solver class to work on
    # d = (REXML::Document.new(get_feed())).root
    d = (REXML::Document.new(File.open('./data/test.xml')))
    return conform_puzzles(d)
  end

  def get_feed(xmlfeed='http://www.threadbender.com/rss.xml')
    #Downloads an XML feed. The default is the test one.
    Net::HTTP.get(URI(xmlfeed))
  end

  def conform_puzzles(doc)
    puzzle_list = Array.new
    doc.each_element("//item") { |e|
          puzzle_list << Puzzle.new(e)
    }
    return puzzle_list
  end

  def go_to_work(which=nil)
    #takes the passed argument from main.rb
      if which
        p = @puzzle_list[which]
         solve(p)
         create_solution(p)
         puts p.crypto + ' - '+ p.author
         puts p.solution
        binding.pry
      else

        @puzzle_list.each { |puzz|
          solve(puzz)
          create_solution(puzz)
          puzz.set_solve_time
          print puzz.solution, "\n"
#          print @calculations, ": Calculations\n"
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
      if !(word.has_possibilities?) then next end
      puzz.solution.gsub!('-'+word.name+' ', '-'+word.possibles.first.to_s+'* ')
      puzz.solution.gsub!(' '+word.name+'-', ' '+word.possibles.first.to_s+'*-')
      puzz.solution.gsub!(' '+word.name+' ', ' '+word.possibles.first.to_s+'* ')
    }
    puzz.solution.strip!
  end

  def solve_with_letters(puzz)
    mask = %w[ E T A O I N S H R D L C U M W F G Y P B V K J X Q Z ]
    @letter_list.each { |k, v|
      if v.possibles.frozen? then next end
      if v.possibles.empty? then next end

      priority = v.possibles.take_while{ |p|
        mask.include? p
      }

      puzz.solution.gsub!(k, priority.first)

    }
  end

  def setup_solve(puzzle)
    cryptogram = puzzle.crypto_broken
    author_section = puzzle.author_broken

    cryptogram.map! {|x| x = Word.new(x, @full_dictionary)}

    author_section.map! {|x| x = Word.new(x, @proper_name_dictionary)}

    author_section.each { |x| x.possibles = *('A'..'Z') if x.length == 1 }
      #Allows single letters in the author section to be any standard initial. "I M Pei" for ex.

    cryptogram.each {|x|
      next if x.has_possibilities?
      x.reload_possibles(@proper_name_dictionary)
    }

    cryptogram.each {|x|
      next if x.has_possibilities?
      x.reload_possibles(@full_dictionary)
    }

    cryptogram += author_section

    cryptogram.sort!{ |x, y|
      x.length <=> y.length
    }

    # binding.pry
    # Now that the author section and crypto section have word objects with each's own dictionary
    # we can work on them in the same way.
    @letter_list = set_letters(puzzle.full_uniques)
    return cryptogram
  end

  def solve(puzzle)
    cryptogram = setup_solve(puzzle)
    # binding.pry

    for z in 1..6

      cryptogram.cycle(2) { |word|
      work_the_word(word)
      }

      3.times do
        @letter_list = kill_singles(@letter_list)
      end

      cryptogram.cycle(2) { |word|
      work_the_word(word)
      }

      if z == 4
        run_smaller_dictionaries(cryptogram - puzzle.author_broken, @popular_dictionary)
      end

    end
    puzzle.full_broken = cryptogram
    puzzle.letter_list = @letter_list
  end


  def run_smaller_dictionaries(broken, dictionary)
    broken.each { |word|
      if word.possibles.length < 2 then next end
        word.possibles = try_dictionary(word, dictionary)
        condense_true(word.uniques, word.possibles)
    }
  end

  def try_dictionary(word, dictionary)
    p = word.possibles.dup
    word.possibles = dictionary.find_possible_matches(word)
    reverse_lookup(word)
    return p if word.has_possibilities? == false

    condense_true(word.uniques, word.possibles)
    return word.possibles
  end

  def kill_singles(letter_hash)
    singulars = letter_hash.dup

    singulars.keep_if { |k, l|
      l.singular?
    }

    letter_hash.each_value { |l|
      next if l.singular?
      l.possibles -= singulars.keys
    }
    return letter_hash
  end

  def work_the_word(word)
      if word.has_possibilities?
        reverse_lookup(word)
        condense_true(word.uniques, word.possibles) if word.has_possibilities?
      end
  end

  def reverse_lookup(word)
    word.possibles.keep_if { |x|
      char_matcher(word.uniques, unique_ify(x))
    }
  end

  def char_matcher(w, p)
    counter = w.length-1                                #Compensates for the array starting at ZERO
    for x in 0..counter                               # Spies across the full length of each word trying to match key letter objects to possbiles
      next if @letter_list[w[x]].possibles.include?(p[x]) # It IS possbile so continue
      return false                                    #This key letter can't be found in the possible solutions
    end
    true   # After checking each character we have no failures of match, so it returns TRUE
  end

  def condense_true(key, p_words)
    # Uses the key words unique letters to match against the matching possbilities. Those are reset to
    # a new possibles list for each letter.
    words = p_words.map { |w| unique_ify(w) }     #Its repetitious to try duplicate characters
                                                  # so we just work with the unique letters

    for position in 0..key.length-1         # POSITION is the spot in both words
      letter = @letter_list[key[position]]     #retrieves the letter OBJ for that position
      if letter.possibles.frozen? then next end # ' AND - are ignored

      letter.possibles.clear     # Resets the letter.possibles list
#      @calculations += 1       # Just an enumerator to gauge how many passes through this method on average
      words.each { |word|       # Chunks down on
#        if letter.possibles.include?(word[position]) then next end
        letter.possibles << word[position]
      }
    end

  end

  def set_letters(salt)
    # Creates a list of letter objects, and includes apostrophes and hypens.
    # SALT is derived from the unique characters of the puzzle, excluding SPACES

    letter_list = Hash.new    #Sets the empty hash for letter objects
    salt.chars { |l|
        letter_list.store(l, Letter.new(l))
        # Uses the key_letter (lowercase) for each character as the HASHkey.
        # The value is the letter object created in the Letter.rb file.
    }
    return letter_list
  end
end

=begin
  def give_continuity_a_try(p, full_broken)
    3.times do
      kill_singles
    end

    known, unknown = split_letters_to_known_unknown(@letter_list)
    if unknown.empty? then return end

    all_sets_of_letters = Array.new
    array = create_letter_sets(known, unknown, all_sets_of_letters)
    return array
  end

  def create_letter_sets(known, unknown, all_sets_of_letters)
    base_array_for_letters = Array.new
    array_of_letters = set_array_of_letters(unknown)

    for horizontal in 0...array_of_letters.length
      for vertical in 1...array_of_letters[horizontal].length
        base_array_for_letters << array_of_letters[horizontal][0].name + array_of_letters[horizontal][vertical]
      end
    end
    return base_array_for_letters
  end

  def combine_arrays_make_unique(array)
    set_of_letters = Set.new
    set_of_possibles = Set.new
    array.each {|e|

      set_of_letters << e[0]
      set_of_possibles << e[1]
      }

    if set_of_letters.length**set_of_possibles.length > 1000 then return nil end

    array = array.combination(set_of_letters.length).to_a

    array.delete_if { |e|
      temp_set_secondary = Set.new
      temp_set = Set.new
      e.each { |y|
        temp_set << y[0]
        temp_set_secondary << y[1]
      }
      temp_set.length != set_of_letters.length || temp_set_secondary.length != set_of_letters.length
    }
    return array
  end


  def set_array_of_letters(unknown)
    array_of_letters_and_possibles = Array.new

    unknown.each_value { |v| # V = a letter object containing more than one possibility
      array_of_letters_and_possibles << [v.dup] + v.possibles.dup
    }
    clear_dup_possibles(array_of_letters_and_possibles)
    return array_of_letters_and_possibles
  end

  def clear_dup_possibles(array)
    array.each { |each_set| # Clears the possibles list so we can play with each one at a time.
      each_set[0].possibles.clear
    }
  end

  def split_letters_to_known_unknown(letter_list)
    known_letters = letter_list.dup
    unknown_letters = letter_list.dup
    known_letters.keep_if { |k, v| v.possibles.frozen? }
    unknown_letters.delete_if { |k, v| v.possibles.frozen? }
    return known_letters, unknown_letters
  end

  def count_words_with_possibles(word_array)
    return word_array.count { |w| w.possibles.length > 0 }
  end

  def check_this_letter_set(new_word_array, temp_letter_list, benchmark)
    new_word_array.each { |w|
      reverse_lookup(w, temp_letter_list)
    }
    if count_words_with_possibles(new_word_array) < benchmark then return false end
    return true
  end
=end
