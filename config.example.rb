SpellekenVanMit.configure do |c|
  # Print debug messages?
  c.debug = ARGV.include?('--debug')

  # General sound volume. 0.0 -> 1.0
  c.sound_volume = 0.25

  # Background music volume. 0.0 -> 1.0
  c.background_volume = 0.025
  c.background_music  = true

  # Which font to use in UI
  c.font_name       = 'Helvetica Neue'
  c.small_font_name = 'Helvetica Neue'

  # Text colors
  c.text_color       = 0xffeeeeee
  c.small_text_color = 0xffcccccc

  # Shake target cards?
  # WARNING: experimental
  c.shake_target_cards = false

  # Draw UI at all?
  c.ui_enabled = true
end
