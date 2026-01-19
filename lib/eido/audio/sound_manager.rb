# frozen_string_literal: true

module Eido
  module Audio
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
  end
end
