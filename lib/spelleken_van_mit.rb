require 'gosu'
require 'ostruct'

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
  ROOT       = File.expand_path('../../', __FILE__)
  VERSION    = '0.1.0'
  CAPTION    = 'Spelleken van mit'
  @_settings = OpenStruct.new
  
  ### SVM
  class << self
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
    IMAGE_DIR = 'images'
    def image_path(file)
      File.join(ROOT, IMAGE_DIR, file)
    end

    # Returns the path to a media file's filename, based on the root directory.
    #
    #   +file+: String
    MEDIA_DIR = 'media'
    def media_path(file)
      File.join(ROOT, MEDIA_DIR, file)
    end
  end
end

# Shortcut
SVM = SpellekenVanMit

require_relative 'spelleken_van_mit/game_window'
require_relative 'spelleken_van_mit/card_set'
