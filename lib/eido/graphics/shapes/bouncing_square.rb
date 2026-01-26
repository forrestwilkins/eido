# frozen_string_literal: true

module Eido
  module Graphics
    module Shapes
      # Bouncing square with smooth color transitions
      # Uses center coordinates internally for consistent collision detection
      class BouncingSquare < AnimatedShape
        def initialize(x:, y:, size:, speed:)
          super(x: x, y: y, speed: speed)
          @size = size
          @half_size = size / 2.0
          @shape = Square.new(x: @x - @half_size, y: @y - @half_size, size: @size)
        end

        def collision_radius
          @half_size * 1.2
        end

        private

        def bounds
          {
            left: @half_size,
            right: Window.width - @half_size,
            top: @half_size,
            bottom: Window.height - @half_size
          }
        end

        def apply_color
          @shape.x = @x - @half_size
          @shape.y = @y - @half_size
          @shape.color = current_color
        end
      end
    end
  end
end
