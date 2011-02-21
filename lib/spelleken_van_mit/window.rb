class SpellekenVanMit::Window < Gosu::Window
  def initialize
    super 800, 600, false
    self.caption = 'Spelleken Van Mit'

    init_cardsets
    init_background
  end

  def update
  end

  def draw
    @background.draw(0, 0, 0)
  end

private

  def init_cardsets
    @card_set = SpellekenVanMit::CardSet.new
    @card_set.populate!
    @game_set = @card_set[0..47]
    @hand_set = @card_set[48..51]
    @hand_set.toggle!
  end

  def init_background
    @background = Gosu::Image.new(self, SpellekenVanMit.image('background.png'), true)
  end
end
