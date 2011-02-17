class SpellekenVanMit::Cards::Base
  attr_reader :identifier

  def initialize(identifier)
    @identifier = identifier
  end

  def type
    self.class.name
  end
end
