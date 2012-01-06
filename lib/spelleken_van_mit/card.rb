module SpellekenVanMit
  ### SVM::Card
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
    def initialize(window, type, identifier)
      @window = window

      @type = type
      raise InvalidCardType.new(type) unless TYPES.include?(type)

      @identifier = identifier
      raise InvalidCardIdentifier.new(identifier) if name.nil?

      @dimensions  = Hash.new
      @destination = [identifier * 75, (TYPES.index(type) + 1) * 100]
      @shown       = false
      @shown_image = Gosu::Image.new(
        @window, SVM::image("#{type}s_#{identifier + 1}.png"), false
      )
    end

    alias dim dimensions

    # Card name, mapped by its identifier.
    def name
      return MAPPING[identifier]
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
      return !!shown
    end

    # Draw this card to the game board.
    def draw(z_order = ZOrder::GAME)
      image.draw pos_x, pos_y, z_order
    end

    # The back image of this card. Same for every card.
    def hidden_image
      return @window.hidden_card_image
    end

    # This card's image instance.
    def image
      return shown ? shown_image : hidden_image
    end

    # Can this card be swapped with another?
    # TODO: Improve this algorithm.
    #
    #   +other+: SVM::CardSet::Card
    def swappable_with?(other)
      return other.is_a?(Card) ? other.within?(*@destination) : false
    end

    # Shortcut
    def pos=(ary)
      self.pos_x = ary.first
      self.pos_y = ary.last
    end
    alias position= pos=

    # Shortcut
    def pos
      return [@pos_x, @pos_y]
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
      return dim[:sx] <= x && dim[:ex] >= x && dim[:sy] <= y && dim[:ey] >= y
    rescue NoMethodError
      raise NotYetPositioned.new(self)
    end

    # Is the card a game breaker?
    def two?
      return identifier == 0
    end
    alias bad? two?

    # How to represent this object in String form.
    def to_s
      "#<Card #{name} of #{type}s>"
    end
  end
end
