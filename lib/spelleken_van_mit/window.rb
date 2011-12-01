module SpellekenVanMit
  ### SVM::Window
  class Window < Gosu::Window
    # The hidden card image.
    attr_reader :hidden_card_image

    # Set up the basic interface and generate the necessary objects.
    def bootstrap
      self.caption = SVM::CAPTION
      #init_background
      init_game_values
      init_sounds
      init_fonts
      init_cardsets
      SVM::Event.fire :after_bootstrap
      at_exit { $stdout.puts "Score: #{score}" }
    end

    # Contains game logic. Called 60 times every second.
    def update
      # 4 bad cards flipped == game over!
      if @hand_set.empty?
        @game_over       = true
        @game_ended_at ||= Time.now.to_i
      end

      if @hand_card
        if dragging?
          @hand_card.pos_x = mouse_x - 35
          @hand_card.pos_y = mouse_y - 48
        end

        shake_target_cards  if SVM::Config['shake_target_cards']
        draw_next_hand_card if @hand_card.bad?
      end

      cleanse_sounds
    end

    # Called after update, draws images and text.
    def draw
      #draw_background

      unless @game_over
        draw_ui
        draw_cards
      else
        draw_score
      end
    end

    # Called on button up.
    #
    #   +button_id+: Integer
    def button_up(button_id)
      case button_id
      when Gosu::Button::MsLeft
        # Don't do anything if we aren't dragging our card.
        return unless dragging?

        begin
          card = @game_set.detect { |c| c.within?(mouse_x, mouse_y) }

          # If no card was found, or this card is already shown, return.
          if card.nil?
            reset_hand_card_position
            return
          end

          # Make sure the player makes a valid swap.
          if card.shown? || (@hand_card && !@hand_card.can_be_swapped_with?(card))
            @wrong_cards_clicked += 1
            reset_hand_card_position
            return
          end

          # Swap the cards' position with the card in hand if
          # this card was not already shown.
          swap_card_with_hand(card)

          # A bad card was flipped!
          if card.bad?
            SVM::Event.fire :bad_card_draw, card
            draw_next_hand_card(card)
          else
            # Show the card.
            card.show!
            SVM::Event.fire :card_show, card

            # The current card in hand is now this card.
            @hand_card = card
            reset_hand_card_position
          end
        ensure
          @target_card = nil
          @dragging    = false
          SVM::Event.fire :dragstop
        end
      when Gosu::Button::KbEscape
        close and exit
      end
    end

    # Called on button down.
    #
    #   +button_id+: Integer
    def button_down(button_id)
      case button_id
      # F2 pressed.
      when Gosu::Button::KbF2
        d { 'F2 pressed, restarting!' + String::EOL }
        # Reset everything.
        init_game_values
        init_cardsets
        SVM::Event.fire :after_restart
      # F3 pressed.
      when Gosu::Button::KbF3
        # NOTE: This is pretty haxy. Should probably remove.
        d { 'F3 pressed, toggling all cards' + String::EOL }
        @game_set.toggle!
      # F4 pressed.
      when Gosu::Button::KbF4
        if SVM::Config['background_music']
          d { 'F4 pressed, toggling background music' + String::EOL }
          @backmusic.playing? ? @backmusic.pause : @backmusic.play(true)
        end
      # Left mouse clicked.
      when Gosu::Button::MsLeft
        if @hand_card.within?(mouse_x, mouse_y)
          @dragging = true
          SVM::Event.fire :dragstart
        end
      end
    end

    # Plays a given Gosu::Sample instance.
    #
    #   +sound+:     Gosu::Sample
    #   +frequency+: Float
    #   +volume+:    Float
    def play_sound(sound, frequency = 1.0, volume = SVM::Config['sound_volume'])
      @sounds << sound.play(frequency, volume)
    end

    # This game needs a visible cursor.
    def needs_cursor?
      true
    end

    # Are we currently dragging a card?
    def dragging?
      @dragging
    end

  protected

    # Time elapsed since start.
    def time_elapsed
      ended = @game_ended_at || Time.now.to_i
      ended - @game_started_at
    end

    def score
      @score ||= begin
        card_score  = @game_set.shown.size * 20
        wrong_cards = @wrong_cards_clicked * 10
        card_score - wrong_cards - time_elapsed
      end
    end

    # Make the next swappable card shake.
    # TODO: Fix the target card click detection in this case.
    #       Targets can't always be clicked because of the position change.
    def shake_target_cards
      if @target_card ||= @game_set.detect { |c| @hand_card.can_be_swapped_with?(c) }
        Time.now.sec % 2 == 0 ? (@target_card.pos_x += 0.04) : (@target_card.pos_x -= 0.04)
      end
    end

    # Remove lingering sounds from memory.
    def cleanse_sounds
      @sounds.reject! { |sound| !sound.playing? && !sound.paused? }
    end

    # Shortcut
    def positions
      SVM::Config['positions']
    end

    # Reset the hand card's position back to its original one.
    def reset_hand_card_position
      @hand_card.set_pos(@hand_position)
    end

    # Swap to next hand card.
    #
    #   +card+: SVM::CardSet::Card
    def draw_next_hand_card(card = nil)
      @bad_card_drawn_at = Time.now.to_i
      play_sound @bad_card_sound

      # Unveil the next card in the hand row.
      card ? @hand_set.delete(card) : @hand_set.shift
      if @hand_card = @hand_set.first
        @hand_position = @hand_card.position
        @hand_card.show!
      end
    end

    # Swap a card's SVM::Config['positions'] with another, and change them around in the sets.
    #
    #   +card+: SVM::CardSet::Card
    def swap_card_with_hand(card)
      #this_pos_x, card.pos_x = card.pos_x, @hand_card.pos_x
      #this_pos_y, card.pos_y = card.pos_y, @hand_card.pos_y
      @hand_card.pos_x = card.pos_x
      @hand_card.pos_y = card.pos_y

      @game_set.delete(card)
      @game_set.push(@hand_card)
      @hand_set.delete(@hand_card)
      @hand_set.push(card)
    end

    # Draw the game's background image.
    def draw_background
      @background.draw *positions['background'], ZOrder::BACKGROUND
    end

    # Draw the game's UI.
    def draw_ui
      draw_small_text "#{caption} v#{SVM::VERSION}", *positions['caption']
      draw_text       "Resterende kaarten: #{@game_set.hidden.size}. Tijd: " \
        "#{time_elapsed} seconden. Fouten: #{@wrong_cards_clicked}",
        *positions['card_status']
      draw_text       'Volgorde:', *positions['order_title']
      draw_small_text '* Klavers', *positions['order_clubs']
      draw_small_text '* Koeken',  *positions['order_diamonds']
      draw_small_text '* Peikes',  *positions['order_spades']
      draw_small_text '* Harten',  *positions['order_hearts']
      if @bad_card_drawn_at && (@bad_card_drawn_at + 4) >= Time.now.to_i
        draw_small_text "Je hebt een 2 getrokken! Nog #{@hand_set.size} " \
          'speelbare kaarten over.', *positions['bad_card']
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
        draw_text "Game over! Er bleven nog #{@game_set.hidden.size} kaarten over. " \
          "Score: #{score}", *positions['game_over']
      else
        draw_text "Gewonnen! Score: #{score}", *positions['you_won']
      end
      draw_text 'Druk op ESC om het spel te verlaten, of F2 om opnieuw te spelen.',
        *positions['quit_or_restart']
    end

  private

    # Draws text using @font.
    #
    #   +text+:    String
    #   +pos_x+:   Integer
    #   +pos_y+:   Integer
    #   +color+:   Gosu::Color
    #   +z_order+: Integer
    def draw_text(text, pos_x, pos_y, color = SVM::Config['text_color'], z_order = ZOrder::UI)
      @font.draw text, pos_x, pos_y, z_order, 1.0, 1.0, color
    end

    # Draws text using @small_font.
    #
    #   +text+:    String
    #   +pos_x+:   Integer
    #   +pos_y+:   Integer
    #   +color+:   Gosu::Color
    #   +z_order+: Integer
    def draw_small_text(text, pos_x, pos_y, color = SVM::Config['small_text_color'], z_order = ZOrder::UI)
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
      @hand_position = @hand_card.position
      @hand_card.show!

      @hidden_card_image = Gosu::Image.new(self, SVM.image('default.png'), false)
    end

    # Initializes the background image.
    def init_background
      @background = Gosu::Image.new(
      # window filename                     tileable posX posY srcX srcY
        self,  SVM.image('background.png'), true,    0,   0,   905, 600
      )
    end

    # Sets up soothing music.
    def init_sounds
      if SVM::Config['background_music']
        @backmusic ||= Gosu::Song.new(self, SVM.media('backmusic.m4a'))
        @backmusic.volume = SVM::Config['background_volume']
        @backmusic.play(true)
      end

      @bad_card_sound ||= Gosu::Sample.new(self, SVM.media('beep.wav'))
    end

    # Initializes the global font.
    def init_fonts
      default     = Gosu.default_font_name
      @font       = Gosu::Font.new(self, SVM::Config['font_name'] || default, 18)
      @small_font = Gosu::Font.new(self, SVM::Config['small_font_name'] || default, 14)
    end

    # Initializes standard values.
    def init_game_values
      @game_over           = false
      @bad_card_drawn_at   = nil
      @wrong_cards_clicked = 0
      @game_started_at     = Time.now.to_i
      @game_ended_at       = nil
      @sounds              = []
      @target_card         = nil
      @score               = nil
      @hand_card           = nil
    end
  end
end
