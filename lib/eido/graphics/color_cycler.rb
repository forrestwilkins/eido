# frozen_string_literal: true

module Eido
  module Graphics
    # Smoothly interpolates between colors over time
    class ColorCycler
      PALETTE = [
        [0.95, 0.26, 0.21], # red
        [0.91, 0.12, 0.39], # pink
        [0.61, 0.15, 0.69], # purple
        [0.25, 0.32, 0.71], # indigo
        [0.13, 0.59, 0.95], # blue
        [0.0,  0.74, 0.83], # cyan
        [0.0,  0.59, 0.53], # teal
        [0.3,  0.69, 0.31], # green
        [1.0,  0.76, 0.03], # yellow
        [1.0,  0.6,  0.0]   # orange
      ].freeze

      def initialize(speed: 0.02, offset: 0)
        @speed = speed
        @progress = offset % 1.0
      end

      def current_color
        idx = (@progress * PALETTE.size).floor
        next_idx = (idx + 1) % PALETTE.size
        blend = (@progress * PALETTE.size) - idx

        lerp_color(PALETTE[idx], PALETTE[next_idx], blend)
      end

      def tick
        @progress = (@progress + @speed) % 1.0
      end

      private

      def lerp_color(c1, c2, t)
        rgb = c1.zip(c2).map { |a, b| a + (b - a) * t }
        [rgb[0], rgb[1], rgb[2], 1.0]
      end
    end
  end
end
