class SpellekenVanMit::CLI
  attr_reader :controller

  def self.start!
    cli = new
  end

  def initialize
    @controller = SpellekenVanMit::Controller.instance
    puts @controller.inspect
  end
end
