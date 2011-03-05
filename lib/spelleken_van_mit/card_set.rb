class SVM::CardSet < Array
  def populate!(window)
    clear

    13.times do |identifier|
      add_card :Club,    window, identifier
      add_card :Diamond, window, identifier
      add_card :Heart,   window, identifier
      add_card :Spade,   window, identifier
    end

    shuffle!
    self
  end

  def toggle!
    each &:toggle
  end

  def inspect
    "#<CardSet #{super}>"
  end

private

  def add_card(type, window, identifier)
    self << SVM::Card.const_get(type).new(window, identifier)
  end
end
