require 'pathname'
require 'gosu'
#require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/module/delegation'

def debug
  return unless SVM.debug?

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

  @debug = true

  ### SVM
  class << self
    attr_accessor :debug

    def root
      Root
    end

    def version
      Version
    end

    def image_path(path)
      root.join('images', path).to_s
    end

    alias :debug? :debug
  end

  ### SVM::Window
  class Window < Gosu::Window
    def initialize
      super 905, 600, false
      self.caption = 'Spelleken Van Mit'

      init_background
      init_font 'Helvetica Neue'
      init_cardsets
    end

    def update
    end

    def draw
      draw_image @background, 0, 0, ZOrder::Background
      draw_text SVM.version, 865, 579

      @game_set.each { |card| draw_image card.image, card.pos_x, card.pos_y }
      @hand_set.each { |card| draw_image card.image, card.pos_x, card.pos_y }
    end

    def button_up(button_id)
      close and exit if button_id == Gosu::Button::KbEscape
    end

    def button_down(button_id)
      @last_button = button_id
      debug { @last_button }
    end

  protected

    def draw_image(image, pos_x, pos_y, z_order = ZOrder::Game)
      image.draw pos_x, pos_y, z_order
    end

    def draw_text(text, pos_x, pos_y, color = 0xffeeeeee, z_order = ZOrder::UI)
      @font.draw text, pos_x, pos_y, z_order, 1.0, 1.0, color
    end

  private

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

    def init_background
      @background = Gosu::Image.new(
      # window, filename,                         tileable, posX, posY, srcX, srcY
        self,   SVM.image_path('background.png'), true,     0,    0,    1000, 600
      )
    end

    def init_font(font_name = Gosu.default_font_name)
      @font = Gosu::Font.new(self, font_name, 18)
    end
  end

  ### SVM::CardSet
  class CardSet
    ### SVM::CardSet::Card
    class Card
      attr_reader :type, :identifier, :shown
      attr_accessor :pos_x, :pos_y

      @@mapping = {
        0  => 'Ace',
        1  => '2',
        2  => '3',
        3  => '4',
        4  => '5',
        5  => '6',
        6  => '7',
        7  => '8',
        8  => '9',
        9  => '10',
        10 => 'Jack',
        11 => 'Queen',
        12 => 'King'
      }

      def initialize(window, type, identifier)
        @window     = window
        @type       = type
        @identifier = identifier
        @shown      = false
      end

      def name
        @@mapping[identifier]
      end

      def toggle
        @shown = !@shown
      end
      alias :toggle! :toggle

      def image
        file = shown ?
          SVM.image_path("#{type}s_#{identifier}.png") :
          SVM.image_path('default.png')
        Gosu::Image.new(@window, file, false)
      end

      def dim_x
        [pos_x, pos_x + 71]
      end

      def dim_y
        [pos_y, pos_y + 96]
      end

      def two?
        identifier == 1
      end
      alias :bad? :two?

      def inspect
        "#<#{name} of #{type}s @shown=#@shown"
      end
    end

    attr_accessor :set

    delegate :each, :each_with_index, :first, :last, :group_by, to: :set

    def initialize(window)
      @window = window
      @set    = []
    end

    def [](idx)
      dup.tap { |d| d.set = @set[idx] }
    end

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

    def toggle!
      each &:toggle!
    end

    def inspect
      "#<CardSet #{@set.inspect}>"
    end

  private

    def add_card(type, identifier)
      @set.push Card.new(@window, type, identifier)
    end
  end
end

# Shortcut
SVM = SpellekenVanMit
