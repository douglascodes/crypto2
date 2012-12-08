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