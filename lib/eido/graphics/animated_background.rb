# frozen_string_literal: true

module Eido
  module Graphics
    # Smoothly animated background that cycles through dark colors
    class AnimatedBackground
      PALETTE = [
        [0.05, 0.05, 0.12], # Deep blue-black
        [0.12, 0.05, 0.15], # Deep purple
        [0.08, 0.10, 0.18], # Navy
        [0.15, 0.08, 0.12], # Dark plum
        [0.05, 0.12, 0.15], # Dark teal
        [0.10, 0.05, 0.18]  # Indigo
      ].freeze

      def initialize(speed: 0.003)
        @speed = speed
        @progress = 0.0
      end

      def current_color
        idx = (@progress * PALETTE.size).floor
        next_idx = (idx + 1) % PALETTE.size
        blend = (@progress * PALETTE.size) - idx

        c1, c2 = PALETTE[idx], PALETTE[next_idx]
        rgb = c1.zip(c2).map { |a, b| a + (b - a) * blend }
        [rgb[0], rgb[1], rgb[2], 1.0]
      end

      def tick
        @progress = (@progress + @speed) % 1.0
      end
    end
  end
end
