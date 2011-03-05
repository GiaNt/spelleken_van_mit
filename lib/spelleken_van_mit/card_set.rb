class SVM::CardSet < Array
  def populate!(window)
    clear

    13.times do |index|
      self << SVM::Card::Club.new(window, index)
      self << SVM::Card::Diamond.new(window, index)
      self << SVM::Card::Heart.new(window, index)
      self << SVM::Card::Spade.new(window, index)
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
