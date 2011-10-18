module SpellekenVanMit
  ### SVM::CardSet
  class CardSet
    ### SVM::CardSet::Card
    class Card
      # All four card types.
      TYPES = [:club, :diamond, :spade, :heart]

      # The card's type. [:club, :diamond, :heart, :spade]
      attr_reader :type

      # The card's internal identifier.
      attr_reader :identifier

      # The card's visibility on the game board.
      attr_reader :shown

      # The card's x position on the game board.
      attr_reader :pos_x

      # The card's y position on the game board.
      attr_reader :pos_y

      # This card's dimensions. Requires pos_y and pos_x to be set.
      attr_reader :dimensions

      # The shown image of this card. Corresponds with its identifier.
      attr_reader :shown_image

      # Mapping of card identifiers to their names.
      MAPPING = %w.2 3 4 5 6 7 8 9 10 jack queen king ace.

      # The image for the back of a card.
      def self.hidden_image
        @_hidden_image ||= Gosu::Image.new(
          $window, SVM.image_path('default.png'), false
        )
      end

      # Initializes a new card.
      #
      #   +type+:       Symbol
      #   +identifier+: Integer
      def initialize(type, identifier)
        @type        = type
        @identifier  = identifier
        @dimensions  = {}
        @final_pos   = [identifier * 75, (TYPES.index(type) + 1) * 100]
        @shown       = false
        @shown_image = Gosu::Image.new(
          $window, SVM.image_path("#{type}s_#{identifier + 1}.png"), false
        )
      end

      alias dim dimensions

      # Card name, mapped by its identifier.
      def name
        MAPPING[identifier]
      end

      # Toggle the card's visibility status.
      def toggle
        @shown = !@shown
      end
      alias toggle! toggle

      # Show this card.
      def show
        @shown = true
      end
      alias show! show

      # Is this card shown?
      def shown?
        !!shown
      end

      # Draw this card to the game board.
      def draw
        (shown ? shown_image : self.class.hidden_image).draw pos_x, pos_y, ZOrder::GAME
      end

      # Can this card be swapped with another?
      # TODO: Improve this algorithm.
      #
      #   +other+: SVM::CardSet::Card
      def can_be_swapped_with?(other)
        return false unless other.is_a?(Card)
        other.within?(*@final_pos)
      end

      # Set this card's x position and also store its dimensions in the hash.
      #
      #   +new_x+: Integer
      def pos_x=(new_x)
        @pos_x   = new_x
        dim[:sx] = new_x - 1
        dim[:ex] = new_x + 72
      end

      # Set this card's y position and also store its dimensions in the hash.
      #
      #   +new_y+: Integer
      def pos_y=(new_y)
        @pos_y   = new_y
        dim[:sy] = new_y - 1
        dim[:ey] = new_y + 97
      end

      # Do the given x and y coordinates lie within this card?
      def within_mouseclick?
        within?($window.mouse_x, $window.mouse_y)
      end

      # Is this card within the given x and y positions?
      #
      #   +x+: Integer
      #   +y+: Integer
      def within?(x, y)
        dim[:sx] <= x && dim[:ex] >= x && dim[:sy] <= y && dim[:ey] >= y
      rescue NoMethodError
        raise "Positions for this card (#{self}) need to be set manually first!"
      end

      # Is the card a game breaker?
      def two?
        identifier == 0
      end
      alias bad? two?

      # How to represent this object in String form.
      def to_s
        "#<Card #{name} of #{type}s>"
      end
    end

    # The cardset's actual cardset.
    attr_accessor :set

    # Array methods are to be called upon the set itself.
    [:each, :each_with_index, :first, :last, :shift, :empty?, :detect,
     :select, :reject, :delete, :push, :size].each do |set_method|
      define_method(set_method) { |*a, &b| @set.send(set_method, *a, &b) }
    end

    # Initializes the cardset.
    def initialize
      @set = []
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
        add_card :club,    identifier
        add_card :diamond, identifier
        add_card :heart,   identifier
        add_card :spade,   identifier
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

  private

    # Adds a card to the set.
    #
    #  +type+:       Symbol
    #  +identifier+: Integer
    def add_card(type, identifier)
      @set.push Card.new(type, identifier)
    end
  end
end
