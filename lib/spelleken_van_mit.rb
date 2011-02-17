$LOAD_PATH.unshift File.dirname(__FILE__)

module SpellekenVanMit
  # Vitals
  autoload :Controller, 'spelleken_van_mit/controller'

  module Cards
    autoload :Base,    'spelleken_van_mit/cards/base'

    autoload :Club,    'spelleken_van_mit/cards/club'
    autoload :Diamond, 'spelleken_van_mit/cards/diamond'
    autoload :Heart,   'spelleken_van_mit/cards/heart'
    autoload :Spade,   'spelleken_van_mit/cards/spade'
  end

  # Other
  autoload :Version, 'spelleken_van_mit/version'

  class SpellekenVanMitError < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end
end
