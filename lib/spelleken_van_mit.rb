require 'pathname'
require 'gosu'
#require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/module/delegation'

# The game window. Needs to be set externally!
$window = nil

def d
  return unless block_given? && SVM.debug?

  debug_info = yield
  debug_info = debug_info.inspect unless debug_info.is_a?(String)

  puts debug_info
end

class Integer #:nodoc:
  def to_fps
    1000.to_f / self.to_f
  end
  alias to_frames_per_second to_fps
end

### ZOrder
module ZOrder
  BACKGROUND, GAME, UI = *0..2
end

### SVM
module SpellekenVanMit
  ROOT    = Pathname.pwd
  VERSION = '0.0.1'

  @debug        = true
  @_image_paths = {}

  ### SVM
  class << self
    # Debug mode boolean.
    attr_accessor :debug
    alias debug? debug

    # Root directory.
    def root
      ROOT
    end

    # Game version.
    def version
      VERSION
    end

    # Returns the path to an image's filename, based on the root directory.
    #
    #   +file+: String
    def image_path(file)
      @_image_paths[file] ||= root.join('images', file).to_s
    end
  end

  ### SVM::Window
  class GameWindow < Gosu::Window
    # Set up the basic interface and generate the necessary objects.
    def bootstrap
      self.caption = 'Spelleken van Mit'
      init_game_values
      init_background
      init_font 'Helvetica Neue'
      init_cardsets
    end

    # Contains game logic. Called 60 times every second.
    def update
      # TODO
    end

    # Called after update, draws images and text.
    def draw
      draw_background

      unless @game_over
        draw_ui
        draw_cards
      else
        draw_score
      end
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
      case @last_button = button_id
      when Gosu::Button::MsLeft
        card = @game_set.detect(&:within_mouseclick?)
        d { card }

        if card.nil? or card.bad?
          @game_over = true
        else
          card.toggle!
        end
      end
    end

    # This game needs a visible cursor.
    def needs_cursor?
      true
    end

  protected

    def draw_background
      @background.draw 0, 0, ZOrder::BACKGROUND
    end

    def draw_ui
      draw_text "Spelleken van Mit v#{SVM.version}", 725, 579
      draw_text "Cards left: #{@game_set.hidden.size}", 5, 579
    end

    def draw_cards
      @game_set.each &:draw
      @hand_set.each &:draw
    end

    def draw_score
      draw_text "There were #{@game_set.hidden.size} cards remaining", 350, 290
    end

  private

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

    # Initializes the CardSet for this game, splits it, and sets its cards'
    # positions.
    def init_cardsets
      card_set = SVM::CardSet.new
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

    # Initializes standard values.
    def init_game_values
      @game_over = false
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

      # The default image to show. The back of a card most likely.
      attr_reader :hidden_image

      # The shown image of this card. Corresponds with its identifier.
      attr_reader :shown_image

      # Mapping of card identifiers to their names.
      MAPPING = %w.ace 2 3 4 5 6 7 8 9 10 jack queen king.

      # Initializes a new card.
      #
      #   +type+:       Symbol
      #   +identifier+: Integer
      def initialize(type, identifier)
        @type         = type
        @identifier   = identifier
        @shown        = false
        @hidden_image = Gosu::Image.new(window, SVM.image_path('default.png'), false)
        @shown_image  = Gosu::Image.new(window, SVM.image_path("#{type}s_#{identifier}.png"), false)
      end

      # Card name, mapped by its identifier.
      def name
        MAPPING[identifier]
      end

      # Toggle the card's visibility status.
      def toggle
        @_image = nil
        @shown  = !@shown
      end
      alias toggle! toggle

      # Draw this card to the game board.
      def draw
        (shown ? @shown_image : @hidden_image).draw pos_x, pos_y, ZOrder::GAME
      end

      # The card's dimensions on the game board.
      def dimensions
        { sx: pos_x, ex: pos_x + 71, sy: pos_y, ey: pos_y + 96 }
      end
      alias dim dimensions

      # Do the given x and y coordinates lie within this card?
      def within_mouseclick?
        x, y = window.mouse_x, window.mouse_y
        dim[:sx] <= x && dim[:ex] >= x && dim[:sy] <= y && dim[:ey] >= y
      end

      # Is the card a game breaker?
      def two?
        identifier == 1
      end
      alias bad? two?

      def inspect
        "#<#{name} of #{type}s @shown=#@shown>"
      end

    private

      def window
        $window or raise 'No game window initialized!'
      end
    end

    # The cardset's actual cardset.
    attr_accessor :set

    # Array methods are to be called upon the set itself.
    delegate :each, :each_with_index, :first, :last,
             :detect, :select, :reject, to: :set

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
      @set.push Card.new(type, identifier)
    end
  end
end

# Shortcut
SVM = SpellekenVanMit
