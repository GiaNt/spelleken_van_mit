class SpellekenVanMit::CardSet < Array
  def populate!(window)
    clear

    13.times do |index|
      self << SpellekenVanMit::Cards::Club.new(window, index)
      self << SpellekenVanMit::Cards::Diamond.new(window, index)
      self << SpellekenVanMit::Cards::Heart.new(window, index)
      self << SpellekenVanMit::Cards::Spade.new(window, index)
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
