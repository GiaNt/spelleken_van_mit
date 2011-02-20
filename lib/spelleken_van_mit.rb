require 'gosu'

$LOAD_PATH.unshift File.dirname(__FILE__)

module SpellekenVanMit
  autoload :CardSet,    'spelleken_van_mit/card_set'
  autoload :Window,     'spelleken_van_mit/window'

  module Cards
    autoload :Base,     'spelleken_van_mit/cards/base'

    autoload :Club,     'spelleken_van_mit/cards/club'
    autoload :Diamond,  'spelleken_van_mit/cards/diamond'
    autoload :Heart,    'spelleken_van_mit/cards/heart'
    autoload :Spade,    'spelleken_van_mit/cards/spade'
  end

  autoload :Version, 'spelleken_van_mit/version'
end
