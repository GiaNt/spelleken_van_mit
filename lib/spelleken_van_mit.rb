require 'pathname'
require 'gosu'
require 'ostruct'
#require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/module/delegation'

# The game window. Needs to be set externally!
$window = nil

def d
  if block_given? && SVM.config.debug
    $stdout.print yield
    $stdout.flush
  end
end

class Integer #:nodoc:
  def to_fps
    1000.to_f / self.to_f
  end
  alias to_frames_per_second to_fps
end

String::EOL = "\r\n"

### ZOrder
module ZOrder
  BACKGROUND, GAME, UI = *0..2
end

### SVM
module SpellekenVanMit
  ROOT       = Pathname.pwd
  VERSION    = '0.0.5'
  @_settings = OpenStruct.new

  ### SVM
  class << self
    # Root directory.
    def root
      ROOT
    end

    # Game version.
    def version
      VERSION
    end

    # Configuration values.
    def config
      if block_given?
        blk = Proc.new # Proc.new refers to the given block in this context; saves performance
        blk.arity == 0 ? @_settings.instance_eval(&blk) : blk.call(@_settings)
      else
        @_settings
      end
    end
    alias configure config

    # Returns the path to an image's filename, based on the root directory.
    #
    #   +file+: String
    def image_path(file)
      root.join('images', file).to_s
    end

    # Returns the path to a media file's filename, based on the root directory.
    #
    #   +file+: String
    def media_path(file)
      root.join('media', file).to_s
    end
  end

  ### SVM::Window
  class GameWindow < Gosu::Window
    # Set up the basic interface and generate the necessary objects.
    def bootstrap
      self.caption = 'Spelleken van mit'
      init_game_values
      init_background
      init_sounds
      init_fonts
      init_cardsets
    end

    # Contains game logic. Called 60 times every second.
    def update
      # 4 bad cards flipped == game over!
      @game_over = true if @hand_set.empty?

      if @hand_card
        if SVM.config.shake_target_cards
          # Make the next swappable card shake.
          if @target_card ||= @game_set.detect { |c| @hand_card.can_be_swapped_with?(c) }
            Time.now.sec % 2 == 0 ? (@target_card.pos_x += 0.1) : (@target_card.pos_x -= 0.1)
          end
        end

        # If the current hand card is a 2, also swap to next hand card.
        if @hand_card.bad?
          @bad_card_drawn_at = Time.now.to_i

          # Unveil the next card in the hand row.
          @hand_set.shift
          @hand_card = @hand_set.first
          @hand_card.show! if @hand_card
        end
      end

      # Don't keep lingering sounds in memory.
      @sounds.reject! { |sound| !sound.playing? && !sound.paused? }
    end

    # Called after update, draws images and text.
    def draw
      draw_background

      unless @game_over
        draw_ui if @ui_enabled
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
        d { "F2 pressed, restarting!\n" }
        restart_game!
      # F3 pressed.
      when Gosu::Button::KbF3
        d { "F3 pressed, toggling ui\n" }
        @ui_enabled = !@ui_enabled
      # F4 pressed.
      when Gosu::Button::KbF4
        # NOTE: This is pretty haxy. Should probably remove.
        d { "F4 pressed, toggling all cards\n" }
        @game_set.toggle!
      # F5 pressed.
      when Gosu::Button::KbF5
        d { "F5 pressed, toggling background music\n" }
        @backmusic.playing? ? @backmusic.pause : @backmusic.play(true)
      # Left mouse clicked.
      when Gosu::Button::MsLeft
        card = @game_set.detect(&:within_mouseclick?)
        d { "\n#{card} " }

        # If no card was found, or this card is already shown, return.
        return if card.nil? or card.shown?
        d { 'was found and not already shown..' }

        # Make sure the player makes a valid swap.
        return unless @hand_card and @hand_card.can_be_swapped_with?(card)
        d { 'can be swapped..' }

        # Swap the cards' position with the card in hand if
        # this card was not already shown.
        swap_card_with_hand(card)
        d { 'was swapped..' }

        # A bad card was flipped!
        if card.bad?
          d { 'was bad!' }

          # Show a message :D.
          @bad_card_drawn_at = Time.now.to_i
          # And also play a sound.
          play_sound @bad_card_sound

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
        @target_card = nil
      end
    end

    # Reset everything.
    def restart_game!
      @backmusic.stop
      init_game_values
      init_sounds
      init_cardsets
    end

    # Plays a given Gosu::Sample instance.
    def play_sound(sound, frequency = 1.0, volume = SVM.config.sound_volume)
      @sounds << sound.play(frequency, volume)
    end

    # Pauses all registered sounds.
    def pause_sounds!
      @sounds.each { |sound| sound.pause if sound.playing? }
    end

    # Resumes all registered sounds.
    def resume_sounds
      @sounds.each { |sound| sound.resume if sound.paused? }
    end

    # This game needs a visible cursor.
    def needs_cursor?
      true
    end

  protected

    def swap_card_with_hand(card)
      this_pos_x, card.pos_x = card.pos_x, @hand_card.pos_x
      this_pos_y, card.pos_y = card.pos_y, @hand_card.pos_y
      @hand_card.pos_x = this_pos_x
      @hand_card.pos_y = this_pos_y

      @game_set.delete(card)
      @game_set.push(@hand_card)
      @hand_set.delete(@hand_card)
      @hand_set.push(card)
    end

    def draw_background
      @background.draw 0, 0, ZOrder::BACKGROUND
    end

    def draw_ui
      draw_small_text "#{caption} v#{SVM.version}", 760, 579
      draw_text "Cards left: #{@game_set.hidden.size}", 5, 579
      draw_text 'Type order:', 95, 445
      draw_small_text '* Clubs', 105, 470
      draw_small_text '* Diamonds', 105, 490
      draw_small_text '* Hearts', 105, 510
      draw_small_text '* Spades', 105, 530
      if @bad_card_drawn_at && (@bad_card_drawn_at + 4) >= Time.now.to_i
        draw_small_text "You've drawn a bad card! #{@hand_set.size} playable cards remain.", 308, 420
      end
    end

    def draw_cards
      @game_set.each &:draw
      @hand_set.each &:draw
    end

    def draw_score
      if @game_set.hidden.size > 0
        draw_text "Game over! There were #{@game_set.hidden.size} cards remaining.", 320, 290
      else
        draw_text 'You won!', 420, 270
      end
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
    def draw_text(text, pos_x, pos_y, color = SVM.config.text_color, z_order = ZOrder::UI)
      @font.draw text, pos_x, pos_y, z_order, 1.0, 1.0, color
    end

    # Draws text using @small_font.
    #
    #   +text+:    String
    #   +pos_x+:   Integer
    #   +pos_y+:   Integer
    #   +color+:   Gosu::Color
    #   +z_order+: Integer
    def draw_small_text(text, pos_x, pos_y, color = SVM.config.small_text_color, z_order = ZOrder::UI)
      @small_font.draw text, pos_x, pos_y, z_order, 1.0, 1.0, color
    end

    # Initializes the CardSet for this game, splits it, and sets its cards'
    # positions.
    def init_cardsets
      card_set = SVM::CardSet.new
      card_set.populate!

      @game_set = card_set[0...48]
      @hand_set = card_set[48...52]

      @game_set.each_with_index do |card, idx|
        card.pos_x = 5 + ((idx % 12) * 75)
        card.pos_y = 5 + ((idx / 12) * 100)
      end
      @hand_set.each_with_index do |card, idx|
        card.pos_x = 305 + (idx * 75)
        card.pos_y = 450
      end

      @hand_card = @hand_set.first
      @hand_card.show!
    end

    # Initializes the background image.
    def init_background
      @background = Gosu::Image.new(
      # window filename                          tileable posX posY srcX srcY
        self,  SVM.image_path('background.png'), true,    0,   0,   905, 600
      )
    end

    # Sets up soothing music.
    def init_sounds
      @backmusic ||= Gosu::Song.new(self, SVM.media_path('backmusic.m4a'))
      @backmusic.volume = SVM.config.background_volume
      @backmusic.play(true) if SVM.config.background_music

      @bad_card_sound ||= Gosu::Sample.new(self, SVM.media_path('beep.wav'))
    end

    # Initializes the global font.
    #
    #   +font_name+: String
    def init_fonts
      default     = Gosu.default_font_name
      @font       = Gosu::Font.new(self, SVM.config.font_name || default, 18)
      @small_font = Gosu::Font.new(self, SVM.config.small_font_name || default, 14)
    end

    # Initializes standard values.
    def init_game_values
      @game_over         = false
      @bad_card_drawn_at = nil
      @ui_enabled        = SVM.config.ui_enabled
      @sounds            = []
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

      # The shown image of this card. Corresponds with its identifier.
      attr_reader :shown_image

      # Mapping of card identifiers to their names.
      MAPPING = %w.2 3 4 5 6 7 8 9 10 jack queen king ace.

      def self.hidden_image
        @_hidden_image ||= Gosu::Image.new($window, SVM.image_path('default.png'), false)
      end

      # Initializes a new card.
      #
      #   +type+:       Symbol
      #   +identifier+: Integer
      def initialize(type, identifier)
        @type        = type
        @identifier  = identifier
        @shown       = false
        @shown_image = Gosu::Image.new(window, SVM.image_path("#{type}s_#{identifier + 1}.png"), false)
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
        (shown ? shown_image : self.class.hidden_image).draw pos_x, pos_y, ZOrder::GAME
      end

      # Can this card be swapped with another?
      # TODO: Improve this algorithm.
      def can_be_swapped_with?(other)
        other.within?(identifier * 75, (TYPES.index(type) + 1) * 100)
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

      def to_s
        "<#{identifier}>#{name} of #{type}s"
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
             :detect, :select, :reject, :delete, :push, :size, to: :set

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
