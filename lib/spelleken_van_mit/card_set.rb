module SpellekenVanMit
  ### SVM::CardSet
  class CardSet
    extend Forwardable
    include Enumerable

    # The cardset's actual cardset.
    attr_accessor :set

    # Call these methods on the actual set.
    def_delegators :@set, :empty?, :delete, :push, :size

    # Initializes the cardset.
    def initialize(window)
      @window = window
      @set    = Array.new
    end

    # Make enumerable work.
    def each
      @set.each { |card| yield card }
    end

    # Retrieve a specific range of cards.
    #
    # First creates a duplicate of this cardset, then adjusts that cardset's
    # actual set to the wanted range.
    #
    #   +cond+: Integer, Range
    def [](cond)
      if cond.is_a?(Range)
        return dup.tap { |d| d.set = @set[cond] }
      else
        return @set[cond]
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
      return reject(&:shown)
    end

    # All shown cards.
    def shown
      return select(&:shown)
    end

    def to_s
      "#<CardSet #{@set.inspect}>"
    end
  end
end
