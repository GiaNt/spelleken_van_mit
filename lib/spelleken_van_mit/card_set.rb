class SpellekenVanMit::CardSet < Array
  def populate!
    clear

    13.times do |index|
      self << SpellekenVanMit::Cards::Club.new(index)
      self << SpellekenVanMit::Cards::Diamond.new(index)
      self << SpellekenVanMit::Cards::Heart.new(index)
      self << SpellekenVanMit::Cards::Spade.new(index)
    end

    self.shuffle!
    self
  end

  def toggle!
    each { |card| card.toggle }
  end

  def inspect
    "#<CardSet #{super}>"
  end
end
