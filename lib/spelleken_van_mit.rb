require 'pathname'
require 'gosu'

$LOAD_PATH.unshift File.dirname(__FILE__)

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
  autoload :Version, 'spelleken_van_mit/version'

  Root = Pathname.pwd

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
      super 800, 600, false
      self.caption = 'Spelleken Van Mit'

      init_cardsets
      init_background
      init_font 'Helvetica Neue'
    end

    def update
    end

    def draw
      draw_image @background, 0, 0, ZOrder::Background
      draw_text 'Spelleken Van Mit', 5, 5
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

    def draw_text(text, pos_x, pos_y, color = 0xffffffff, z_order = ZOrder::UI)
      @font.draw text, pos_x, pos_y, z_order, 1.0, 1.0, color
    end

  private

    def init_cardsets
      @card_set = SVM::CardSet.new(self)
      @card_set.populate!
      debug { @card_set }
      # TODO: Game set / Hand set
    end

    def init_background
      @background = Gosu::Image.new(self, SVM.image_path('background.png'), true)
    end

    def init_font(font_name = Gosu.default_font_name)
      @font = Gosu::Font.new(self, font_name, 18)
    end
  end

  ### SVM::CardSet
  class CardSet
    def initialize(window)
      @window = window
      @set    = []
    end

    def populate!
      @set.clear

      13.times do |identifier|
        add_card :Club,    identifier
        add_card :Diamond, identifier
        add_card :Heart,   identifier
        add_card :Spade,   identifier
      end

      @set.shuffle!
    end

    def toggle!
      @set.each &:toggle!
    end

    def inspect
      "#<CardSet #{@set.inspect}>"
    end

  private

    def add_card(type, identifier)
      if SVM::Card.const_defined?(type)
        @set.push SVM::Card.const_get(type).new(@window, identifier)
      end
    end
  end

  ### SVM::Card
  module Card
    ### SVM::Card::Base
    class Base
      attr_reader :identifier, :shown

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

      def initialize(window, identifier)
        @window     = window
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

      # TODO: Different image as per @shown
      def image
        if shown
        else
        end
      end

      def two?
        identifier == 1
      end
      alias :bad? :two?

      def type
        self.class.to_s.sub(/([a-z]+::)+/i, '')
      end

      def inspect
        "#<#{name} of #{type}s @shown=#@shown"
      end
    end

    ### SVM::Card::Club
    class Club < Base
    end

    ### SVM::Card::Diamond
    class Diamond < Base
    end

    ### SVM::Card::Heart
    class Heart < Base
    end

    ### SVM::Card::Spade
    class Spade < Base
    end
  end
end

# Shortcut
SVM = SpellekenVanMit
