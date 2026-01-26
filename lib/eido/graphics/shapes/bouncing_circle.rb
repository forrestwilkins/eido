# frozen_string_literal: true

module Eido
  module Graphics
    module Shapes
      # Bouncing circle with smooth color transitions
      class BouncingCircle < AnimatedShape
        def initialize(x:, y:, radius:, speed:)
          super(x: x, y: y, speed: speed)
          @radius = radius
          @shape = Circle.new(x: @x, y: @y, radius: @radius)
        end

        def collision_radius
          @radius
        end

        private

        def bounds
          {
            left: @radius,
            right: Window.width - @radius,
            top: @radius,
            bottom: Window.height - @radius
          }
        end

        def apply_color
          @shape.x = @x
          @shape.y = @y
          @shape.color = current_color
        end
      end
    end
  end
end
