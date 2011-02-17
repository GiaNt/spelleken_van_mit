class SpellekenVanMit::Controller
  attr_reader :card_set

  def self.instance
    @instance ||= new
    yield @instance if block_given?
    @instance
  end

  def initialize
    @card_set = SpellekenVanMit::CardSet.new
    @card_set.populate!
  end
end
