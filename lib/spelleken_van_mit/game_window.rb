module SpellekenVanMit
  ### SVM::Window
  class GameWindow < Gosu::Window
    # Set up the basic interface and generate the necessary objects.
    def bootstrap
      self.caption = SVM::CAPTION
      init_game_values
      init_background
      init_sounds
      init_fonts
      init_cardsets
    end

    # Contains game logic. Called 60 times every second.
    def update
      # 4 bad cards flipped == game over!
      @game_over = true if @hand_set.empty?

      if @hand_card
        if SVM.config.shake_target_cards
          # Make the next swappable card shake.
          # TODO: Fix the target card click detection in this case.
          #       Targets can't always be clicked because of the position change.
          if @target_card ||= @game_set.detect { |c| @hand_card.can_be_swapped_with?(c) }
            Time.now.sec % 2 == 0 ? (@target_card.pos_x += 0.1) : (@target_card.pos_x -= 0.1)
          end
        end

        # If the current hand card is a 2, also swap to next hand card.
        if @hand_card.bad?
          @bad_card_drawn_at = Time.now.to_i
          play_sound @bad_card_sound

          # Unveil the next card in the hand row.
          @hand_set.shift
          @hand_card = @hand_set.first
          @hand_card.show! if @hand_card
        end
      end

      # Don't keep lingering sounds in memory.
      @sounds.reject! { |sound| !sound.playing? && !sound.paused? }
    end

    # Called after update, draws images and text.
    def draw
      draw_background

      unless @game_over
        draw_ui if @ui_enabled
        draw_cards
      else
        draw_score
      end
    end

    # Called on button up.
    #
    #   +button_id+: Integer
    def button_up(button_id)
      close and exit if button_id == Gosu::Button::KbEscape
    end

    # Called on button down.
    #
    #   +button_id+: Integer
    def button_down(button_id)
      case @last_button = button_id
      # F2 pressed.
      when Gosu::Button::KbF2
        d { "F2 pressed, restarting!\n" }
        # Reset everything.
        @backmusic.stop
        init_game_values
        init_sounds
        init_cardsets
      # F3 pressed.
      when Gosu::Button::KbF3
        d { "F3 pressed, toggling ui\n" }
        @ui_enabled = !@ui_enabled
      # F4 pressed.
      when Gosu::Button::KbF4
        # NOTE: This is pretty haxy. Should probably remove.
        d { "F4 pressed, toggling all cards\n" }
        @game_set.toggle!
      # F5 pressed.
      when Gosu::Button::KbF5
        d { "F5 pressed, toggling background music\n" }
        @backmusic.playing? ? @backmusic.pause : @backmusic.play(true)
      # Left mouse clicked.
      when Gosu::Button::MsLeft
        card = @game_set.detect(&:within_mouseclick?)
        d { "\n#{card} " }

        # If no card was found, or this card is already shown, return.
        return if card.nil? or card.shown?
        d { 'was found and not already shown..' }

        # Make sure the player makes a valid swap.
        return unless @hand_card and @hand_card.can_be_swapped_with?(card)
        d { 'can be swapped..' }

        # Swap the cards' position with the card in hand if
        # this card was not already shown.
        swap_card_with_hand(card)
        d { 'was swapped..' }

        # A bad card was flipped!
        if card.bad?
          d { 'was bad!' }

          # Show a message :D.
          @bad_card_drawn_at = Time.now.to_i
          # And also play a sound.
          play_sound @bad_card_sound

          # Remove this card from the game set.
          @hand_set.delete(card)

          # Unveil the next card in the hand row.
          @hand_card = @hand_set.first
          @hand_card.show! if @hand_card
        else
          # Show the card.
          card.show!
          # The current card in hand is now this card.
          @hand_card = card
        end
        @target_card = nil
      end
    end

    # Plays a given Gosu::Sample instance.
    #
    #   +sound+:     Gosu::Sample
    #   +frequency+: Float
    #   +volume+:    Float
    def play_sound(sound, frequency = 1.0, volume = SVM.config.sound_volume)
      @sounds << sound.play(frequency, volume)
    end

    # This game needs a visible cursor.
    def needs_cursor?
      true
    end

  protected

    # Swap a card's positions with another, and change them around in the sets.
    #
    #   +card+: SVM::CardSet::Card
    def swap_card_with_hand(card)
      this_pos_x, card.pos_x = card.pos_x, @hand_card.pos_x
      this_pos_y, card.pos_y = card.pos_y, @hand_card.pos_y
      @hand_card.pos_x = this_pos_x
      @hand_card.pos_y = this_pos_y

      @game_set.delete(card)
      @game_set.push(@hand_card)
      @hand_set.delete(@hand_card)
      @hand_set.push(card)
    end

    # Draw the game's background image.
    def draw_background
      @background.draw 0, 0, ZOrder::BACKGROUND
    end

    # Draw the game's UI.
    def draw_ui
      draw_small_text "#{caption} v#{SVM::VERSION}", 760, 579
      draw_text "Cards left: #{@game_set.hidden.size}", 5, 579
      draw_text 'Type order:', 95, 445
      draw_small_text '* Clubs', 105, 470
      draw_small_text '* Diamonds', 105, 490
      draw_small_text '* Spades', 105, 510
      draw_small_text '* Hearts', 105, 530
      if @bad_card_drawn_at && (@bad_card_drawn_at + 4) >= Time.now.to_i
        draw_small_text "You've drawn a bad card! #{@hand_set.size} playable cards remain.", 308, 420
      end
    end

    # Draw all the cards.
    def draw_cards
      @game_set.each &:draw
      @hand_set.each &:draw
    end

    # Draw the score upon game over.
    def draw_score
      if @game_set.hidden.size > 0
        draw_text "Game over! There were #{@game_set.hidden.size} cards remaining.", 310, 290
      else
        draw_text 'You won!', 420, 270
      end
      draw_text 'Press ESC to exit, or F2 to play again.', 330, 310
    end

  private

    # Draws text using @font.
    #
    #   +text+:    String
    #   +pos_x+:   Integer
    #   +pos_y+:   Integer
    #   +color+:   Gosu::Color
    #   +z_order+: Integer
    def draw_text(text, pos_x, pos_y, color = SVM.config.text_color, z_order = ZOrder::UI)
      @font.draw text, pos_x, pos_y, z_order, 1.0, 1.0, color
    end

    # Draws text using @small_font.
    #
    #   +text+:    String
    #   +pos_x+:   Integer
    #   +pos_y+:   Integer
    #   +color+:   Gosu::Color
    #   +z_order+: Integer
    def draw_small_text(text, pos_x, pos_y, color = SVM.config.small_text_color, z_order = ZOrder::UI)
      @small_font.draw text, pos_x, pos_y, z_order, 1.0, 1.0, color
    end

    # Initializes the CardSet for this game, splits it, and sets its cards'
    # positions.
    def init_cardsets
      card_set = SVM::CardSet.new
      card_set.populate!

      @game_set = card_set[0...48]
      @hand_set = card_set[48...52]

      @game_set.each_with_index do |card, idx|
        card.pos_x = 5 + ((idx % 12) * 75)
        card.pos_y = 5 + ((idx / 12) * 100)
      end
      @hand_set.each_with_index do |card, idx|
        card.pos_x = 305 + (idx * 75)
        card.pos_y = 450
      end

      @hand_card = @hand_set.first
      @hand_card.show!
    end

    # Initializes the background image.
    def init_background
      @background = Gosu::Image.new(
      # window filename                          tileable posX posY srcX srcY
        self,  SVM.image_path('background.png'), true,    0,   0,   905, 600
      )
    end

    # Sets up soothing music.
    def init_sounds
      @backmusic ||= Gosu::Song.new(self, SVM.media_path('backmusic.m4a'))
      @backmusic.volume = SVM.config.background_volume
      @backmusic.play(true) if SVM.config.background_music

      @bad_card_sound ||= Gosu::Sample.new(self, SVM.media_path('beep.wav'))
    end

    # Initializes the global font.
    def init_fonts
      default     = Gosu.default_font_name
      @font       = Gosu::Font.new(self, SVM.config.font_name || default, 18)
      @small_font = Gosu::Font.new(self, SVM.config.small_font_name || default, 14)
    end

    # Initializes standard values.
    def init_game_values
      @game_over         = false
      @bad_card_drawn_at = nil
      @ui_enabled        = SVM.config.ui_enabled
      @sounds            = []
    end
  end
end
