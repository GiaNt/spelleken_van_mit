require 'pathname'
require 'gosu'

$LOAD_PATH.unshift File.dirname(__FILE__)

module SpellekenVanMit
  Root = Pathname.pwd

  autoload :CardSet, 'spelleken_van_mit/card_set'
  autoload :Window,  'spelleken_van_mit/window'

  module Card
    autoload :Base,    'spelleken_van_mit/card/base'

    autoload :Club,    'spelleken_van_mit/card/club'
    autoload :Diamond, 'spelleken_van_mit/card/diamond'
    autoload :Heart,   'spelleken_van_mit/card/heart'
    autoload :Spade,   'spelleken_van_mit/card/spade'
  end

  autoload :Version, 'spelleken_van_mit/version'

  def self.root
    Root
  end

  def self.version
    Version
  end

  def self.image_path(path)
    root.join('images', path).to_s
  end

  def self.z_order
    @_z_order ||= { background: 0, cards: 1, ui: 2 }
  end
end

# Shortcut
SVM = SpellekenVanMit
