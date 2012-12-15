class Puzzle
  attr_accessor :crypto, :crypto_broken, :solution, :author_sol, :author, :publ_date, :solve_time,
    :uniques, :full_uniques, :let_list, :author_broken, :full_broken
  def initialize(crypto='ABCDEF', author="Bace Troncons", publ_date=Time.now)
    @crypto = crypto          #The seperated cryptogram from the author section
    @author = author          #The seperated author section for the crpytogram
    @publ_date = publ_date    #The seperated date value
    @solve_time = nil         #Var for the date/time the solution was first made
    @uniques = unique_ify(@crypto)
    @full_uniques = unique_ify((@crypto + @author)).delete(" ")
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

    @author_broken = Array.new
    @author_broken += @author.split
    hyphens = Array.new
    @author_broken.each { |w|
       if w.include? '-' then hyphens += w.split(/-/) end
     }

    @author_broken.delete_if { |w|
      w.include? '-'
    }

    @author_broken += hyphens
    @author_broken = @author_broken.each.sort { |a,b|  #Sorts words by size
    unique_ify(a).length <=> unique_ify(b).length  
  }
  end

  def to_s
    print 'Code: ', @crypto,  "\nDate: ", @publ_date, "\nCompleted: ", @solve_time, "\n"
  end
end