module SpellekenVanMit
  ### SVM::CardSet
  class CardSet
    ### SVM::CardSet::Card
    class Card
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

      # All four card types.
      TYPES = [:club, :diamond, :spade, :heart]

      # Mapping of card identifiers to their names.
      MAPPING = %w[2 3 4 5 6 7 8 9 10 jack queen king ace]

      # Initializes a new card.
      #
      #   +type+:       Symbol
      #   +identifier+: Integer
      def initialize(type, identifier)
        raise SVM::InvalidCardType, type unless TYPES.include?(type)

        @type        = type
        @identifier  = identifier
        @dimensions  = {}
        @destination = [identifier * 75, (TYPES.index(type) + 1) * 100]
        @shown       = false
        @shown_image = Gosu::Image.new(
          $window, SVM.image("#{type}s_#{identifier + 1}.png"), false
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
        image.draw pos_x, pos_y, ZOrder::GAME
      end

      # The back image of this card. Same for every card.
      def hidden_image
        $window.hidden_card_image
      end

      # This card's image instance.
      def image
        shown ? shown_image : hidden_image
      end

      # Can this card be swapped with another?
      # TODO: Improve this algorithm.
      #
      #   +other+: SVM::CardSet::Card
      def can_be_swapped_with?(other)
        other.is_a?(Card) ? other.within?(*@destination) : false
      end

      # Shortcut
      def set_pos(ary)
        self.pos_x = ary.first
        self.pos_y = ary.last
      end
      alias set_position set_pos

      # Shortcut
      def pos
        [@pos_x, @pos_y]
      end
      alias position pos

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
        dim[:sy] = new_y
        dim[:ey] = new_y + 96
      end

      # Is this card within the given x and y positions?
      #
      #   +x+: Integer
      #   +y+: Integer
      def within?(x, y)
        dim[:sx] <= x && dim[:ex] >= x && dim[:sy] <= y && dim[:ey] >= y
      rescue NoMethodError
        raise SVM::NotYetPositioned,
          "Positions for this card (#{self}) need to be set manually first!"
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
    [ :each, :each_with_index, :first, :last, :shift, :empty?,
      :detect, :select, :reject, :delete, :push, :size
    ].each do |set_method|
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
      SVM::Event.fire :before_populate, @set

      13.times do |identifier|
        add_card :club,    identifier
        add_card :diamond, identifier
        add_card :heart,   identifier
        add_card :spade,   identifier
      end

      @set.shuffle!
      SVM::Event.fire :after_populate, @set
      @set
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
      Card.new(type, identifier).tap do |card|
        @set << card
        SVM::Event.fire :card_add, @set, card
      end
    end
  end
end
