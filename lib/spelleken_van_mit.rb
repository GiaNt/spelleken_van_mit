require 'pathname'
require 'gosu'
#require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/module/delegation'

def debug
  return unless block_given? && SVM.debug?

  debug_info = yield
  debug_info = debug_info.inspect unless debug_info.is_a?(String)

  puts debug_info
end

### ZOrder
module ZOrder
  Background, Game, UI = *0..2
end

### SVM
module SpellekenVanMit
  Root    = Pathname.pwd
  Version = '0.0.1'
  @debug  = true

  ### SVM
  class << self
    # Debug mode boolean.
    attr_accessor :debug

    # Root directory.
    def root
      Root
    end

    # Game version.
    def version
      Version
    end

    # Returns the path to an image's filename, based on the root directory.
    #
    #   +file+: String
    def image_path(file)
      root.join('images', file).to_s
    end

    alias :debug? :debug
  end

  ### SVM::Window
  class Window < Gosu::Window
    def initialize
      super 905, 600, false, 33.333333
      self.caption = 'Spelleken Van Mit'

      init_background
      init_font 'Helvetica Neue'
      init_cardsets
    end

    # Contains game logic. Called 60 times every second.
    def update
      if button_down?(Gosu::Button::MsLeft)
        if card = @game_set.detect { |c| c.within_dimension?(@mouse_x, @mouse_y) }
          card.toggle!
          debug { card }
        end
      end
    end

    # Called after update, draws images and text.
    def draw
      @background.draw 0, 0, ZOrder::Background
      draw_text SVM.version, 865, 579
      draw_text "Cards left: #{@game_set.hidden.size}" , 5, 579

      @game_set.each &:draw
      @hand_set.each &:draw
    end

    # Called on button up.
    #
    #   +button_id+: Integer
    def button_up(button_id)
      close and exit if button_id == Gosu::Button::KbEscape
    end

    # Called on button down.
    #
    #   +button_id+: Integer
    def button_down(button_id)
      @last_button = button_id
      @mouse_x     = mouse_x
      @mouse_y     = mouse_y
    end

    # This game needs a cursor.
    def needs_cursor?
      true
    end

  protected

    # Draws text using @font.
    #
    #   +text+:    String
    #   +pos_x+:   Integer
    #   +pos_y+:   Integer
    #   +color+:   Gosu::Color
    #   +z_order+: Integer
    def draw_text(text, pos_x, pos_y, color = 0xffeeeeee, z_order = ZOrder::UI)
      @font.draw text, pos_x, pos_y, z_order, 1.0, 1.0, color
    end

  private

    # Initializes the CardSet for this game, splits it, and sets its cards'
    # positions.
    def init_cardsets
      card_set = SVM::CardSet.new(self)
      card_set.populate!

      @game_set = card_set[0...48]
      @hand_set = card_set[48...52].tap { |s| s.first.toggle! }

      @game_set.each_with_index do |card, idx|
        card.pos_x = 5 + ((idx % 12) * 75)
        card.pos_y = 5 + ((idx / 12) * 100)
      end
      @hand_set.each_with_index do |card, idx|
        card.pos_x = 305 + (idx * 75)
        card.pos_y = 450
      end
    end

    # Initializes the background image.
    def init_background
      @background = Gosu::Image.new(
      # window filename                          tileable posX posY srcX srcY
        self,  SVM.image_path('background.png'), true,    0,   0,   905, 600
      )
    end

    # Initializes the global font.
    #
    #   +font_name+: String
    def init_font(font_name = Gosu.default_font_name)
      @font = Gosu::Font.new(self, font_name, 18)
    end
  end

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
      attr_accessor :pos_x

      # The card's y position on the game board.
      attr_accessor :pos_y

      # Mapping of card identifiers to their names.
      @@mapping = {
        0  => 'ace',
        1  => '2',
        2  => '3',
        3  => '4',
        4  => '5',
        5  => '6',
        6  => '7',
        7  => '8',
        8  => '9',
        9  => '10',
        10 => 'jack',
        11 => 'queen',
        12 => 'king'
      }

      # Initializes a new card.
      #
      #   +window+:     Gosu::Window
      #   +type+:       Symbol
      #   +identifier+: Integer
      def initialize(window, type, identifier)
        @window     = window
        @type       = type
        @identifier = identifier
        @shown      = false
      end

      # Card name, mapped by its identifier.
      def name
        @@mapping[identifier]
      end

      # Toggle the card's visibility status.
      def toggle
        @shown = !@shown
      end
      alias :toggle! :toggle

      # Draw this card to the game board.
      def draw
        image = begin
          file = shown ?
            SVM.image_path("#{type}s_#{identifier}.png") :
            SVM.image_path('default.png')
          Gosu::Image.new(@window, file, false)
        end

        image.draw pos_x, pos_y, ZOrder::Game
      end

      # The card's dimensions on the game board.
      def dimensions
        { sx: pos_x, ex: pos_x + 71, sy: pos_y, ey: pos_y + 96 }
      end
      alias :dim :dimensions

      # Do the given x and y coordinates lie within this card?
      def within_dimension?(x, y)
        dim[:sx] <= x && dim[:ex] >= x && dim[:sy] <= y && dim[:ey] >= y
      end

      # Is the card a game breaker?
      def two?
        identifier == 1
      end
      alias :bad? :two?

      def inspect
        "#<#{name} of #{type}s @shown=#@shown>"
      end
    end

    # The cardset's actual cardset.
    attr_accessor :set

    # Array methods are to be called upon the set itself.
    delegate :each, :each_with_index, :first, :last,
             :detect, :select, :reject, to: :set

    # Initializes the cardset.
    #
    #   +window+: Gosu::Window
    def initialize(window)
      @window = window
      @set    = []
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

    # All hidden cards.
    def hidden
      reject &:shown
    end

    # All shown cards.
    def shown
      select &:shown
    end

    def inspect
      "#<CardSet #{@set.inspect}>"
    end

  private

    # Adds a card to the set.
    #
    #  +type+:       Symbol
    #  +identifier+: Integer
    def add_card(type, identifier)
      @set.push Card.new(@window, type, identifier)
    end
  end
end

# Shortcut
SVM = SpellekenVanMit
