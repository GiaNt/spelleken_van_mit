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
      # 4 bad cards flipped == game over!
      @game_over = true if @hand_set.empty?

      # If the current hand card is a 2, also swap to next.
      if @hand_card and @hand_card.bad?
        # Unveil the next card in the hand row.
        @hand_set.shift
        @hand_card = @hand_set.first
        @hand_card.show!
      end
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
      # F2 pressed.
      when Gosu::Button::KbF2
        d { 'F2 pressed, restarting!' }
        restart_game!
      # Left mouse clicked.
      when Gosu::Button::MsLeft
        card = @game_set.detect(&:within_mouseclick?)
        d { card }

        # If no card was found, or this card is already shown, return.
        return if card.nil? or card.shown?

        # Make sure the player makes a valid swap.
        return unless @hand_card.can_be_swapped_with?(card)

        # Swap the cards' position with the card in hand if
        # this card was not already shown.
        card.swap_position_with @hand_card
        @game_set.delete(card)
        @game_set.push(@hand_card)
        @hand_set.delete(@hand_card)
        @hand_set.push(card)

        # A bad card was flipped!
        if card.bad?
          # Remove this card from the game set.
          @hand_set.delete(card)

          # Unveil the next card in the hand row.
          @hand_card = @hand_set.first
          @hand_card.show! if @hand_card
        else
          # Show the card.
          card.show!
          # The current card in hand is now this card.
          @hand_card = card
        end
      end
    end

    # Reset everything.
    def restart_game!
      init_game_values
      init_cardsets
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
      draw_text "There were #{@game_set.hidden.size} cards remaining!", 350, 290
      draw_text 'Press ESC to exit, or F2 to play again.', 330, 310
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
      @hand_card = @hand_set.first
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
      @game_over         = false
    end
  end

  ### SVM::CardSet
  class CardSet
    ### SVM::CardSet::Card
    class Card
      # All four card types.
      TYPES = [:club, :diamond, :heart, :spade]

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
      MAPPING = %w.2 3 4 5 6 7 8 9 10 jack queen king ace.

      # Initializes a new card.
      #
      #   +type+:       Symbol
      #   +identifier+: Integer
      def initialize(type, identifier)
        @type         = type
        @identifier   = identifier
        @shown        = false
        @hidden_image = Gosu::Image.new(window, SVM.image_path('default.png'), false)
        @shown_image  = Gosu::Image.new(window, SVM.image_path("#{type}s_#{identifier + 1}.png"), false)
      end

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
        (shown ? @shown_image : @hidden_image).draw pos_x, pos_y, ZOrder::GAME
      end

      # Can this card be swapped with another?
      def can_be_swapped_with?(other)
        other.within?(identifier  * 75, (TYPES.index(type) + 1) * 100)
      end

      # Swap position with another card.
      def swap_position_with(other)
        this_pos_x, self.pos_x = pos_x, other.pos_x
        this_pos_y, self.pos_y = pos_y, other.pos_y
        other.pos_x = this_pos_x
        other.pos_y = this_pos_y

        other
      end

      # The card's dimensions on the game board.
      def dimensions
        { sx: pos_x, ex: pos_x + 71, sy: pos_y, ey: pos_y + 96 }
      end
      alias dim dimensions

      # Do the given x and y coordinates lie within this card?
      def within_mouseclick?
        within?(window.mouse_x, window.mouse_y)
      end

      # Is this card within the given x and y positions?
      def within?(x, y)
        dim[:sx] <= x && dim[:ex] >= x && dim[:sy] <= y && dim[:ey] >= y
      end

      # Is the card a game breaker?
      def two?
        identifier == 0
      end
      alias bad? two?

      def inspect
        "#<#{name} of #{type}s @identifier=#@identifier"
      end

    private

      def window
        $window or raise 'No game window initialized!'
      end
    end

    # The cardset's actual cardset.
    attr_accessor :set

    # Array methods are to be called upon the set itself.
    delegate :each, :each_with_index, :first, :last, :shift, :empty?,
             :detect, :select, :reject, :delete, :push, to: :set

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
