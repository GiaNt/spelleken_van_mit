class SpellekenVanMit::Cards::Base
  attr_reader :identifier

  def initialize(identifier)
    @identifier = identifier
  end

  def type
    self.class.to_s.sub(/([a-z]+::)+/i, '')
  end

  def inspect
    "#<#{type} @identifier=#@identifier>"
  end
end
