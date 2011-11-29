require 'gosu'
require 'yaml'

# The game window. Needs to be set externally!
$window = nil

def d
  if block_given? && SVM::Config['debug']
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
  ROOT      = File.expand_path('../../', __FILE__)
  VERSION   = '0.4.1'
  CAPTION   = 'Spelleken van mit'
  IMAGE_DIR = 'images'
  MEDIA_DIR = 'media'
  # Configuration values.
  Config    = YAML::load_file(File.join(ROOT, 'config.yml'))

  class << Config
    def to_s
      inject '' do |str, (option, value)|
        str << "  #{option}: #{value}" + String::EOL
      end
    end
  end

  ### SVM
  class << self
    # Returns the path to an image's filename, based on the root directory.
    #
    #   +file+: String
    def image(file)
      File.join(ROOT, IMAGE_DIR, file)
    end

    # Returns the path to a media file's filename, based on the root directory.
    #
    #   +file+: String
    def media(file)
      File.join(ROOT, MEDIA_DIR, file)
    end
  end

  # SVM Error class.
  class Error < StandardError; end

  # Error to raise when a card with no positions is being checked for
  # dimensions.
  class NotYetPositioned < Error
    def initialize(card)
      super "Positions for this card (#{card}) must be set manually first."
    end
  end

  # Error to raise when a card is initialized with an invalid type.
  class InvalidCardType < Error
    def initialize(type)
      super "Invalid card type: #{type}"
    end
  end

  # Error to raise when a card is initialized with an invalid identifier.
  class InvalidCardIdentifier < Error
    def initialize(identifier)
      super "Invalid card identifier: #{identifier}"
    end
  end

  class EventDispatcher
    def initialize
      clear_events!
    end

    def clear_events!
      @events = Hash.new { |h, k| h[k] = [] }
    end

    def on(event, &block)
      @events[event] << block
    end

    def fire(event, *args)
      @events[event].each { |cbk| cbk.call(*args) }
    end
  end

  Event = EventDispatcher.new
end
# Shortcut
SVM = SpellekenVanMit

require_relative 'spelleken_van_mit/window'
require_relative 'spelleken_van_mit/card_set'
