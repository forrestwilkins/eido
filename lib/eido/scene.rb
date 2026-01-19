# frozen_string_literal: true

module Eido
  # Orchestrates all animated shapes and background
  class Scene
    def initialize(width, height)
      @width = width
      @height = height
      @shapes = []
      @sound_manager = Audio::SoundManager.new
      @background = Graphics::AnimatedBackground.new
      setup_shapes
    end

    def update
      @background.tick
      Window.set(background: @background.current_color)
      @shapes.each(&:update)
      handle_collisions
    end

    private

    def handle_collisions
      @shapes.each_with_index do |shape_a, i|
        @shapes[(i + 1)..].each do |shape_b|
          shape_a.collide_with!(shape_b) if shape_a.colliding_with?(shape_b)
        end
      end
    end

    def setup_shapes
      add_circles
      add_squares
      add_triangles
      @shapes.each { |shape| shape.sound_manager = @sound_manager }
    end

    def add_circles
      3.times do
        @shapes << Graphics::Shapes::BouncingCircle.new(
          x: rand(50..(@width - 50)),
          y: rand(50..(@height - 50)),
          radius: rand(25..50),
          speed: rand(1.5..3.0)
        )
      end
    end

    def add_squares
      1.times do
        @shapes << Graphics::Shapes::BouncingSquare.new(
          x: rand(50..(@width - 100)),
          y: rand(50..(@height - 100)),
          size: rand(40..70),
          speed: rand(1.5..2.5)
        )
      end
    end

    def add_triangles
      1.times do
        @shapes << Graphics::Shapes::BouncingTriangle.new(
          x: rand(80..(@width - 80)),
          y: rand(80..(@height - 80)),
          size: rand(30..55),
          speed: rand(2.0..3.5)
        )
      end
    end
  end
end
