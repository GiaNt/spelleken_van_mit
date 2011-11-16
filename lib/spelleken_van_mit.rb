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
  ROOT        = File.expand_path('../../', __FILE__)
  VERSION     = '0.3.0'
  CAPTION     = 'Spelleken van mit'
  IMAGE_DIR   = 'images'
  MEDIA_DIR   = 'media'
  CONFIG_FILE = 'config.yml'

  # Configuration values.
  Config      = YAML::load_file(File.join(ROOT, CONFIG_FILE))

  class << Config
    def to_s
      str = '-- SVM::Config' + String::EOL
      each do |option, value|
        str << "   #{option} => #{value}" + String::EOL
      end
      str
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
end

# Shortcut
SVM = SpellekenVanMit

require_relative 'spelleken_van_mit/game_window'
require_relative 'spelleken_van_mit/card_set'
