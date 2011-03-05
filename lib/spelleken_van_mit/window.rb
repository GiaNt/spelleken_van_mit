class SVM::Window < Gosu::Window
  def initialize
    super 800, 600, false
    self.caption = 'Spelleken Van Mit'

    init_cardsets
    init_background
  end

  def update
  end

  def draw
    @background.draw(0, 0, ZOrder::Background)
  end

  def button_up(id)
    close if id == Gosu::Button::KbEscape
  end

  #def button_down(id)
  #end

private

  def init_cardsets
    @card_set = SVM::CardSet.new
    @card_set.populate!(self)
    # TODO: Game set / Hand set
  end

  def init_background
    @background = Gosu::Image.new(self, SVM.image_path('background.png'), true)
  end
end
