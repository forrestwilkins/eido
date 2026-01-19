# Smooth animated shapes using Ruby 2D

require 'fileutils'
require 'ruby2d'

module Eido
  # Generates retro distorted sparkle WAV files with echo
  module SparkleGenerator
    SAMPLE_RATE = 44_100
    SOUNDS_DIR = File.join(__dir__, 'sounds')
    VERSION = 1  # Bump this to regenerate sounds when design changes

    # Echo settings - longer delays for retro feel
    ECHO_DELAYS = [0.08, 0.18, 0.3]
    ECHO_DECAYS = [0.5, 0.3, 0.15]

    # Retro effect settings
    BIT_DEPTH = 6          # Bit crush depth (lower = more crunchy)
    DOWNSAMPLE = 4         # Sample rate reduction factor
    NOISE_AMOUNT = 0.02    # Background noise level

    # Frequencies for the sparkle variations
    FREQUENCIES = [1800, 2200, 2800, 3200, 3800].freeze

    def self.generate_all
      FileUtils.mkdir_p(SOUNDS_DIR)

      return if sounds_up_to_date?

      # Clear old sounds and regenerate
      Dir.glob(File.join(SOUNDS_DIR, '*.wav')).each { |f| File.delete(f) }

      # Use fixed seed for deterministic generation
      srand(42)

      FREQUENCIES.each_with_index do |freq, i|
        generate_sparkle("sparkle_#{i}.wav", frequency: freq, duration: 0.1)
      end

      # Reset random seed
      srand

      write_version_file
    end

    def self.sounds_up_to_date?
      version_file = File.join(SOUNDS_DIR, '.version')
      return false unless File.exist?(version_file)
      return false unless FREQUENCIES.each_index.all? { |i| File.exist?(File.join(SOUNDS_DIR, "sparkle_#{i}.wav")) }

      File.read(version_file).strip == VERSION.to_s
    end

    def self.write_version_file
      File.write(File.join(SOUNDS_DIR, '.version'), VERSION.to_s)
    end

    def self.generate_sparkle(filename, frequency:, duration:)
      path = File.join(SOUNDS_DIR, filename)

      total_duration = duration + ECHO_DELAYS.last + 0.1
      total_samples = (SAMPLE_RATE * total_duration).to_i
      original_samples = (SAMPLE_RATE * duration).to_i

      # Generate the original sparkle sound
      original = Array.new(original_samples) do |i|
        t = i.to_f / SAMPLE_RATE
        envelope = Math.exp(-t * 35)
        amplitude = 0.08 * envelope

        freq_sweep = frequency * (1 + t * 1.5)
        wave = Math.sin(2 * Math::PI * freq_sweep * t)
        wave += 0.4 * Math.sin(3 * Math::PI * freq_sweep * t)
        wave += 0.2 * Math.sin(5 * Math::PI * freq_sweep * t)

        # Add slight detuned layer for thickness
        wave += 0.3 * Math.sin(2 * Math::PI * (freq_sweep * 1.01) * t)

        wave * amplitude
      end

      # Apply retro effects to original
      original = apply_retro_effects(original)

      # Create output buffer with echoes
      data = Array.new(total_samples, 0.0)
      original.each_with_index { |v, i| data[i] += v }

      # Add echoes with increasing distortion
      ECHO_DELAYS.each_with_index do |delay, idx|
        offset = (delay * SAMPLE_RATE).to_i
        decay = ECHO_DECAYS[idx]
        # Each echo gets more crushed
        crushed_echo = apply_retro_effects(original, extra_crush: idx + 1)
        crushed_echo.each_with_index do |v, i|
          data[i + offset] += v * decay if i + offset < total_samples
        end
      end

      # Final soft clip for warmth
      data = data.map { |v| soft_clip(v, 0.12) }

      int_data = data.map { |v| (v * 32_767).to_i.clamp(-32_768, 32_767) }
      write_wav(path, int_data)
    end

    def self.apply_retro_effects(samples, extra_crush: 0)
      crush_depth = BIT_DEPTH - extra_crush
      crush_depth = [crush_depth, 3].max

      samples.each_with_index.map do |v, i|
        # Downsample (sample and hold)
        idx = (i / DOWNSAMPLE) * DOWNSAMPLE
        v = samples[[idx, samples.size - 1].min]

        # Bit crush
        steps = (2**crush_depth).to_f
        v = (v * steps).round / steps

        # Add subtle noise
        v += (rand - 0.5) * NOISE_AMOUNT

        # Soft waveshaping distortion
        soft_clip(v, 0.15)
      end
    end

    def self.soft_clip(x, threshold)
      return x if x.abs < threshold
      sign = x >= 0 ? 1 : -1
      sign * (threshold + (1 - threshold) * Math.tanh((x.abs - threshold) / (1 - threshold)))
    end

    def self.write_wav(path, samples)
      File.open(path, 'wb') do |f|
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
    attr_accessor :sound_manager, :velocity_x, :velocity_y

    MAX_SPEED = 4.0  # Cap velocity to prevent acceleration over time

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

    # Collision radius for physics (treat all shapes as circles)
    def collision_radius
      raise NotImplementedError
    end

    # Check if colliding with another shape
    def colliding_with?(other)
      dx = other.x - @x
      dy = other.y - @y
      distance = Math.sqrt(dx * dx + dy * dy)
      min_dist = collision_radius + other.collision_radius
      distance < min_dist
    end

    # Bounce collision - shapes reflect off each other like walls
    def collide_with!(other)
      dx = other.x - @x
      dy = other.y - @y
      distance = Math.sqrt(dx * dx + dy * dy)
      return if distance.zero?

      # Normal vector pointing from self to other
      nx = dx / distance
      ny = dy / distance

      # Separate overlapping shapes first
      overlap = collision_radius + other.collision_radius - distance
      return if overlap <= 0

      half_overlap = overlap / 2.0 + 1.0
      @x -= half_overlap * nx
      @y -= half_overlap * ny
      other.instance_variable_set(:@x, other.x + half_overlap * nx)
      other.instance_variable_set(:@y, other.y + half_overlap * ny)

      # Reflect velocities off the collision normal (like bouncing off a wall)
      # Self bounces away from other
      dot_self = @velocity_x * nx + @velocity_y * ny
      if dot_self > 0  # Moving toward other
        @velocity_x -= 2 * dot_self * nx
        @velocity_y -= 2 * dot_self * ny
      end

      # Other bounces away from self
      dot_other = other.velocity_x * (-nx) + other.velocity_y * (-ny)
      if dot_other > 0  # Moving toward self
        other.velocity_x -= 2 * dot_other * (-nx)
        other.velocity_y -= 2 * dot_other * (-ny)
      end

      # Clamp velocities to prevent speed accumulation
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
      @half_size * 1.2 # Approximate as circle
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

  # Smoothly animated background
  class AnimatedBackground
    PALETTE = [
      [0.05, 0.05, 0.12],  # Deep blue-black
      [0.12, 0.05, 0.15],  # Deep purple
      [0.08, 0.10, 0.18],  # Navy
      [0.15, 0.08, 0.12],  # Dark plum
      [0.05, 0.12, 0.15],  # Dark teal
      [0.10, 0.05, 0.18],  # Indigo
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

  # Orchestrates all animated shapes
  class Scene
    def initialize(width, height)
      @width = width
      @height = height
      @shapes = []
      @sound_manager = SoundManager.new
      @background = AnimatedBackground.new
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
      # Add circles
      5.times do
        @shapes << BouncingCircle.new(
          x: rand(50..(@width - 50)),
          y: rand(50..(@height - 50)),
          radius: rand(25..50),
          speed: rand(1.5..3.0)
        )
      end

      # Add squares
      4.times do
        @shapes << BouncingSquare.new(
          x: rand(50..(@width - 100)),
          y: rand(50..(@height - 100)),
          size: rand(40..70),
          speed: rand(1.5..2.5)
        )
      end

      # Add triangles
      4.times do
        @shapes << BouncingTriangle.new(
          x: rand(80..(@width - 80)),
          y: rand(80..(@height - 80)),
          size: rand(30..55),
          speed: rand(2.0..3.5)
        )
      end

      # Assign sound manager to all shapes
      @shapes.each { |shape| shape.sound_manager = @sound_manager }
    end
  end
end

# Run the animation in fullscreen
set title: 'eido', fullscreen: true
set background: [0.05, 0.05, 0.12]

# Exit on Escape or Q
on :key_down do |event|
  close if %w[escape q].include?(event.key)
end

# Wait for window to initialize, then create scene with actual dimensions
scene = nil

update do
  if scene.nil?
    scene = Eido::Scene.new(Window.width, Window.height)
  end
  scene.update
end

show
