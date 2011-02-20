class SpellekenVanMit::Window < Gosu::Window
  def initialize
    super 640, 480, false
    self.caption = 'Spelleken Van Mit'

    init_cardsets!
  end

  def update
  end

  def draw
  end

private

  def init_cardsets!
    @card_set = SpellekenVanMit::CardSet.new
    @card_set.populate!
    @game_set = @card_set[0..47]
    @hand_set = @card_set[48..51]
    @hand_set.toggle!
  end
end
