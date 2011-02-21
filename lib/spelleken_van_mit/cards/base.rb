class SpellekenVanMit::Cards::Base
  attr_reader :identifier
  attr_accessor :shown

  @@mapping = {
    0  => 'Ace',
    1  => '2',
    2  => '3',
    3  => '4',
    4  => '5',
    5  => '6',
    6  => '7',
    7  => '8',
    8  => '9',
    9  => '10',
    10 => 'Jack',
    11 => 'Queen',
    12 => 'King'
  }

  def initialize(window, identifier)
    @window     = window
    @shown      = false
    @identifier = identifier
  end

  def name
    @@mapping[identifier]
  end

  def toggle
    @shown = !@shown
  end

  def image
    # TODO
    if @shown
    else
    end
  end

  def two?
    identifier == 1
  end
  alias_method :bad?, :two?

  def type
    self.class.to_s.sub(/([a-z]+::)+/i, '')
  end

  def inspect
    "#<#{name} of #{type}s @shown=#@shown"
  end
end