# frozen_string_literal: true

module Eido
  module Audio
    # Generates retro distorted sparkle WAV files with echo
    module SparkleGenerator
      SAMPLE_RATE = 44_100
      SOUNDS_DIR = File.expand_path('../../../sounds', __dir__)
      VERSION = 1 # Bump this to regenerate sounds when design changes

      # Echo settings - longer delays for retro feel
      ECHO_DELAYS = [0.08, 0.18, 0.3].freeze
      ECHO_DECAYS = [0.5, 0.3, 0.15].freeze

      # Retro effect settings
      BIT_DEPTH = 6
      DOWNSAMPLE = 4
      NOISE_AMOUNT = 0.02

      # Frequencies for the sparkle variations
      FREQUENCIES = [1800, 2200, 2800, 3200, 3800].freeze

      class << self
        def generate_all
          FileUtils.mkdir_p(SOUNDS_DIR)

          return if sounds_up_to_date?

          Dir.glob(File.join(SOUNDS_DIR, '*.wav')).each { |f| File.delete(f) }

          # Use fixed seed for deterministic generation
          srand(42)

          FREQUENCIES.each_with_index do |freq, i|
            generate_sparkle("sparkle_#{i}.wav", frequency: freq, duration: 0.1)
          end

          srand

          write_version_file
        end

        def sounds_up_to_date?
          version_file = File.join(SOUNDS_DIR, '.version')
          return false unless File.exist?(version_file)
          return false unless FREQUENCIES.each_index.all? do |i|
            File.exist?(File.join(SOUNDS_DIR, "sparkle_#{i}.wav"))
          end

          File.read(version_file).strip == VERSION.to_s
        end

        private

        def write_version_file
          File.write(File.join(SOUNDS_DIR, '.version'), VERSION.to_s)
        end

        def generate_sparkle(filename, frequency:, duration:)
          path = File.join(SOUNDS_DIR, filename)

          total_duration = duration + ECHO_DELAYS.last + 0.1
          total_samples = (SAMPLE_RATE * total_duration).to_i
          original_samples = (SAMPLE_RATE * duration).to_i

          original = generate_wave(original_samples, frequency)
          original = apply_retro_effects(original)

          data = mix_with_echoes(original, total_samples)
          data = data.map { |v| soft_clip(v, 0.12) }

          int_data = data.map { |v| (v * 32_767).to_i.clamp(-32_768, 32_767) }
          write_wav(path, int_data)
        end

        def generate_wave(samples, frequency)
          Array.new(samples) do |i|
            t = i.to_f / SAMPLE_RATE
            envelope = Math.exp(-t * 35)
            amplitude = 0.08 * envelope

            freq_sweep = frequency * (1 + t * 1.5)
            wave = Math.sin(2 * Math::PI * freq_sweep * t)
            wave += 0.4 * Math.sin(3 * Math::PI * freq_sweep * t)
            wave += 0.2 * Math.sin(5 * Math::PI * freq_sweep * t)
            wave += 0.3 * Math.sin(2 * Math::PI * (freq_sweep * 1.01) * t)

            wave * amplitude
          end
        end

        def mix_with_echoes(original, total_samples)
          data = Array.new(total_samples, 0.0)
          original.each_with_index { |v, i| data[i] += v }

          ECHO_DELAYS.each_with_index do |delay, idx|
            offset = (delay * SAMPLE_RATE).to_i
            decay = ECHO_DECAYS[idx]
            crushed_echo = apply_retro_effects(original, extra_crush: idx + 1)
            crushed_echo.each_with_index do |v, i|
              data[i + offset] += v * decay if i + offset < total_samples
            end
          end

          data
        end

        def apply_retro_effects(samples, extra_crush: 0)
          crush_depth = [BIT_DEPTH - extra_crush, 3].max

          samples.each_with_index.map do |v, i|
            idx = (i / DOWNSAMPLE) * DOWNSAMPLE
            v = samples[[idx, samples.size - 1].min]

            steps = (2**crush_depth).to_f
            v = (v * steps).round / steps
            v += (rand - 0.5) * NOISE_AMOUNT

            soft_clip(v, 0.15)
          end
        end

        def soft_clip(x, threshold)
          return x if x.abs < threshold

          sign = x >= 0 ? 1 : -1
          sign * (threshold + (1 - threshold) * Math.tanh((x.abs - threshold) / (1 - threshold)))
        end

        def write_wav(path, samples)
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
    end
  end
end
