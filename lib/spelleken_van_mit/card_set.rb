class SVM::CardSet < Array
  def initialize(window)
    @window = window
  end

  def populate!
    clear

    13.times do |identifier|
      add_card :Club,    identifier
      add_card :Diamond, identifier
      add_card :Heart,   identifier
      add_card :Spade,   identifier
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

  def add_card(type, identifier)
    self << SVM::Card.const_get(type).new(@window, identifier)
  end
end
