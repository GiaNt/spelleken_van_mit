require 'gosu'
require 'yaml'
require 'forwardable'

# The game window. Needs to be set externally!
def d
  if block_given? && SVM::Config['debug']
    $stdout.print yield
    $stdout.flush
  end
end

class Integer #:nodoc:
  def to_fps
    return 1000.to_f / self.to_f
  end
  alias to_frames_per_second to_fps
end

class Object #:nodoc:
  def presence
    return self unless (respond_to?(:empty?) ? empty? : !self)
  end
end

String::EOL = "\r\n"

### SVM
module SpellekenVanMit extend self
  ROOT    = File.expand_path('../../', __FILE__)
  VERSION = '0.5.1'.freeze

  # Configuration values.
  Config  = YAML.load_file(ROOT + '/config.yml')

  # Prettyprint config values.
  def Config.to_s
    inject '' do |str, (option, value)|
      str << "  #{option}: #{value}" + String::EOL
    end
  end

  # Returns the path to an image's filename, based on the root directory.
  #
  #   +filename+: String
  def image(filename)
    return ROOT + '/images/' + filename
  end

  # Returns the path to a media file's filename, based on the root directory.
  #
  #   +filename+: String
  def media(filename)
    return ROOT + '/media/' + filename
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
end
# Shortcut
SVM = SpellekenVanMit

require_relative 'spelleken_van_mit/z_order'
require_relative 'spelleken_van_mit/window'
require_relative 'spelleken_van_mit/card_set'
require_relative 'spelleken_van_mit/card'
