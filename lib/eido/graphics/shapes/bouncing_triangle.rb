# frozen_string_literal: true

module Eido
  module Graphics
    module Shapes
      # Bouncing triangle with gradient colors
      class BouncingTriangle < AnimatedShape
        def initialize(x:, y:, size:, speed:)
          super(x: x, y: y, speed: speed)
          @size = size
          @color_cyclers = Array.new(3) { ColorCycler.new(speed: 0.012, offset: rand) }
          @shape = Triangle.new(
            x1: @x, y1: @y - @size,
            x2: @x - @size, y2: @y + @size,
            x3: @x + @size, y3: @y + @size
          )
        end

        def collision_radius
          @size
        end

        def update
          move
          bounce
          @color_cyclers.each(&:tick)
          apply_color
        end

        private

        def bounds
          {
            left: @size,
            right: Window.width - @size,
            top: @size,
            bottom: Window.height - @size
          }
        end

        def apply_color
          @shape.x1 = @x
          @shape.y1 = @y - @size
          @shape.x2 = @x - @size
          @shape.y2 = @y + @size
          @shape.x3 = @x + @size
          @shape.y3 = @y + @size
          @shape.color = @color_cyclers.map(&:current_color)
        end
      end
    end
  end
end
