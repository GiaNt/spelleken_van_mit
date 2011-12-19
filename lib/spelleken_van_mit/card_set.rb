module SpellekenVanMit
  ### SVM::CardSet
  class CardSet
    # The cardset's actual cardset.
    attr_accessor :set

    # Array methods are to be called upon the set itself.
    [ :each, :each_with_index, :first, :last, :shift, :empty?,
      :detect, :select, :reject, :delete, :push, :size
    ].each do |set_method|
      define_method(set_method) { |*a, &b| @set.send(set_method, *a, &b) }
    end

    # Initializes the cardset.
    def initialize(window)
      @window = window
      @set    = Array.new
    end

    # Retrieve a specific range of cards.
    #
    # First creates a duplicate of this cardset, then adjusts that cardset's
    # actual set to the wanted range.
    #
    #   +cond+: Integer, Range
    def [](cond)
      if cond.is_a?(Range)
        dup.tap { |d| d.set = @set[cond] }
      else
        @set[cond]
      end
    end

    # Populates this cardset with all 52 cards.
    #
    # First clears any existing cards, then adds 13 cards of all 4 types.
    # Finally, shuffles the whole set around to randomize it.
    def populate!
      @set.clear

      13.times do |identifier|
        @set << Card.new(@window, :club,    identifier)
        @set << Card.new(@window, :diamond, identifier)
        @set << Card.new(@window, :heart,   identifier)
        @set << Card.new(@window, :spade,   identifier)
      end

      @set.shuffle!
    end

    # Toggles each of this cardset's cards visibility status.
    def toggle!
      each &:toggle!
    end

    # Set each of this cardset's cards visibility status to shown.
    def show!
      each &:show!
    end

    # All hidden cards.
    def hidden
      reject &:shown
    end

    # All shown cards.
    def shown
      select &:shown
    end

    def to_s
      "#<CardSet #{@set.inspect}>"
    end
  end
end
