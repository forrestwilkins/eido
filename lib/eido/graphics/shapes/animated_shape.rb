# frozen_string_literal: true

module Eido
  module Graphics
    module Shapes
      # Base class for all animated shapes
      class AnimatedShape
        attr_reader :x, :y
        attr_accessor :sound_manager, :velocity_x, :velocity_y

        MAX_SPEED = 4.0

        def initialize(x:, y:, speed:, color_speed: 0.015)
          @x = x.to_f
          @y = y.to_f
          @base_speed = speed
          @velocity_x = rand(-speed..speed)
          @velocity_y = rand(-speed..speed)
          @color_cycler = ColorCycler.new(speed: color_speed, offset: rand)
          @sound_manager = nil
        end

        def update
          move
          bounce
          @color_cycler.tick
          apply_color
        end

        def collision_radius
          raise NotImplementedError
        end

        def colliding_with?(other)
          dx = other.x - @x
          dy = other.y - @y
          distance = Math.sqrt(dx * dx + dy * dy)
          min_dist = collision_radius + other.collision_radius
          distance < min_dist
        end

        def collide_with!(other)
          dx = other.x - @x
          dy = other.y - @y
          distance = Math.sqrt(dx * dx + dy * dy)
          return if distance.zero?

          nx = dx / distance
          ny = dy / distance

          overlap = collision_radius + other.collision_radius - distance
          return if overlap <= 0

          half_overlap = overlap / 2.0 + 1.0
          @x -= half_overlap * nx
          @y -= half_overlap * ny
          other.instance_variable_set(:@x, other.x + half_overlap * nx)
          other.instance_variable_set(:@y, other.y + half_overlap * ny)

          dot_self = @velocity_x * nx + @velocity_y * ny
          if dot_self > 0
            @velocity_x -= 2 * dot_self * nx
            @velocity_y -= 2 * dot_self * ny
          end

          dot_other = other.velocity_x * (-nx) + other.velocity_y * (-ny)
          if dot_other > 0
            other.velocity_x -= 2 * dot_other * (-nx)
            other.velocity_y -= 2 * dot_other * (-ny)
          end

          clamp_velocity!
          other.clamp_velocity!

          @sound_manager&.play
        end

        def clamp_velocity!
          speed = Math.sqrt(@velocity_x**2 + @velocity_y**2)
          return if speed <= MAX_SPEED

          scale = MAX_SPEED / speed
          @velocity_x *= scale
          @velocity_y *= scale
        end

        private

        def move
          @x += @velocity_x
          @y += @velocity_y
        end

        def bounce
          bounced = false

          if @x <= bounds[:left] || @x >= bounds[:right]
            @velocity_x *= -1
            @x = @x.clamp(bounds[:left], bounds[:right])
            bounced = true
          end

          if @y <= bounds[:top] || @y >= bounds[:bottom]
            @velocity_y *= -1
            @y = @y.clamp(bounds[:top], bounds[:bottom])
            bounced = true
          end

          @sound_manager&.play if bounced
        end

        def bounds
          raise NotImplementedError
        end

        def apply_color
          raise NotImplementedError
        end

        def current_color
          @color_cycler.current_color
        end
      end
    end
  end
end
