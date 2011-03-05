class SVM::CardSet
  def initialize(window)
    @window = window
    @set    = []
  end

  def populate!
    @set.clear

    13.times do |identifier|
      add_card :Club,    identifier
      add_card :Diamond, identifier
      add_card :Heart,   identifier
      add_card :Spade,   identifier
    end

    @set.shuffle!
  end

  def toggle!
    @set.each &:toggle
  end

  def inspect
    "#<CardSet #{@set.inspect}>"
  end

private

  def add_card(type, identifier)
    if SVM::Card.const_defined?(type)
      @set.push SVM::Card.const_get(type).new(@window, identifier)
    end
  end
end
