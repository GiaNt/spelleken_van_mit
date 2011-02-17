class SpellekenVanMit::CardSet < Hash
  CARD_TYPES = [:spades, :hearts, :clubs, :diamonds]

  def initialize(*)
    super { |h, k| h[k] = [] }
  end

  CARD_TYPES.each do |card_type|
    define_method(card_type) { self[card_type] }
  end

  def populate!
    clear

    13.times do |index|
      self[:clubs]    << SpellekenVanMit::Cards::Club.new(index)
      self[:diamonds] << SpellekenVanMit::Cards::Diamond.new(index)
      self[:hearts]   << SpellekenVanMit::Cards::Heart.new(index)
      self[:spades]   << SpellekenVanMit::Cards::Spade.new(index)
    end

    self
  end

  def inspect
    "#<CardSet #{super}>"
  end
end
