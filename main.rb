# Smooth animated shapes using Ruby 2D

require 'fileutils'
require 'ruby2d'

module Eido
  # Generates simple sparkle WAV files
  module SparkleGenerator
    SAMPLE_RATE = 44_100
    SOUNDS_DIR = File.join(__dir__, 'sounds')

    def self.generate_all
      FileUtils.mkdir_p(SOUNDS_DIR)
      # Clear old sounds to regenerate with new settings
      Dir.glob(File.join(SOUNDS_DIR, '*.wav')).each { |f| File.delete(f) }

      # Generate sparkles at higher pitches for more sparkle
      [2400, 3200, 4000, 4800, 5600].each_with_index do |freq, i|
        generate_sparkle("sparkle_#{i}.wav", frequency: freq, duration: 0.08)
      end
    end

    def self.generate_sparkle(filename, frequency:, duration:)
      path = File.join(SOUNDS_DIR, filename)

      samples = (SAMPLE_RATE * duration).to_i
      data = Array.new(samples) do |i|
        t = i.to_f / SAMPLE_RATE
        # Very fast exponential decay for that quick sparkle
        envelope = Math.exp(-t * 50)
        # Much softer amplitude
        amplitude = 0.06 * envelope

        # Frequency rises slightly for sparkle effect
        freq_sweep = frequency * (1 + t * 2)
        wave = Math.sin(2 * Math::PI * freq_sweep * t)
        # Multiple harmonics for shimmery quality
        wave += 0.5 * Math.sin(3 * Math::PI * freq_sweep * t)
        wave += 0.25 * Math.sin(5 * Math::PI * freq_sweep * t)
        wave += 0.15 * Math.sin(7 * Math::PI * freq_sweep * t)

        (wave * amplitude * 32_767).to_i.clamp(-32_768, 32_767)
      end

      write_wav(path, data)
    end

    def self.write_wav(path, samples)
      File.open(path, 'wb') do |f|
        # WAV header
        f.write('RIFF')
        f.write([36 + samples.size * 2].pack('V'))
        f.write('WAVE')
        f.write('fmt ')
        f.write([16, 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16].pack('VvvVVvv'))
        f.write('data')
        f.write([samples.size * 2].pack('V'))
        f.write(samples.pack('s*'))
      end
    end
  end

  # Manages sparkle sound playback
  class SoundManager
    def initialize
      SparkleGenerator.generate_all
      @sounds = Dir.glob(File.join(SparkleGenerator::SOUNDS_DIR, '*.wav')).map do |path|
        Sound.new(path)
      end
    end

    def play
      return if @sounds.empty?

      @sounds.sample.play
    end
  end
  WINDOW_WIDTH = 640
  WINDOW_HEIGHT = 480

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
      [1.0,  0.6,  0.0],  # orange
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

  # Base class for all animated shapes
  class AnimatedShape
    attr_reader :x, :y
    attr_accessor :sound_manager

    def initialize(x:, y:, speed:, color_speed: 0.015)
      @x = x.to_f
      @y = y.to_f
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

  # Bouncing circle with smooth color transitions
  class BouncingCircle < AnimatedShape
    def initialize(x:, y:, radius:, speed:)
      super(x: x, y: y, speed: speed)
      @radius = radius
      @shape = Circle.new(x: @x, y: @y, radius: @radius)
    end

    private

    def bounds
      {
        left: @radius,
        right: WINDOW_WIDTH - @radius,
        top: @radius,
        bottom: WINDOW_HEIGHT - @radius
      }
    end

    def apply_color
      @shape.x = @x
      @shape.y = @y
      @shape.color = current_color
    end
  end

  # Bouncing square with smooth color transitions
  class BouncingSquare < AnimatedShape
    def initialize(x:, y:, size:, speed:)
      super(x: x, y: y, speed: speed)
      @size = size
      @shape = Square.new(x: @x, y: @y, size: @size)
    end

    private

    def bounds
      {
        left: 0,
        right: WINDOW_WIDTH - @size,
        top: 0,
        bottom: WINDOW_HEIGHT - @size
      }
    end

    def apply_color
      @shape.x = @x
      @shape.y = @y
      @shape.color = current_color
    end
  end

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
        right: WINDOW_WIDTH - @size,
        top: @size,
        bottom: WINDOW_HEIGHT - @size
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

  # Orchestrates all animated shapes
  class Scene
    def initialize
      @shapes = []
      @sound_manager = SoundManager.new
      setup_shapes
    end

    def update
      @shapes.each(&:update)
    end

    private

    def setup_shapes
      # Add circles
      3.times do
        @shapes << BouncingCircle.new(
          x: rand(50..590),
          y: rand(50..430),
          radius: rand(20..40),
          speed: rand(1.5..3.0)
        )
      end

      # Add squares
      2.times do
        @shapes << BouncingSquare.new(
          x: rand(50..540),
          y: rand(50..380),
          size: rand(30..60),
          speed: rand(1.5..2.5)
        )
      end

      # Add triangles
      2.times do
        @shapes << BouncingTriangle.new(
          x: rand(80..560),
          y: rand(80..400),
          size: rand(25..45),
          speed: rand(2.0..3.5)
        )
      end

      # Assign sound manager to all shapes
      @shapes.each { |shape| shape.sound_manager = @sound_manager }
    end
  end
end

# Run the animation
set title: 'eido', width: Eido::WINDOW_WIDTH, height: Eido::WINDOW_HEIGHT
set background: [0.12, 0.12, 0.14]

scene = Eido::Scene.new

update do
  scene.update
end

show
