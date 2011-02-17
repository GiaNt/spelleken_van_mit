class SpellekenVanMit::CLI
  def self.start!
    cli = new
  end

  def initialize
    controller = SpellekenVanMit::Controller.new
    controller.card_set = SpellekenVanMit::CardSet.new
  end
end
