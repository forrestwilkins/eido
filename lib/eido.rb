# frozen_string_literal: true

require 'fileutils'
require 'ruby2d'

require_relative 'eido/version'
require_relative 'eido/audio/sparkle_generator'
require_relative 'eido/audio/sound_manager'
require_relative 'eido/graphics/color_cycler'
require_relative 'eido/graphics/animated_background'
require_relative 'eido/graphics/shapes/animated_shape'
require_relative 'eido/graphics/shapes/bouncing_circle'
require_relative 'eido/graphics/shapes/bouncing_square'
require_relative 'eido/graphics/shapes/bouncing_triangle'
require_relative 'eido/scene'

module Eido
  extend Ruby2D::DSL

  class << self
    def run
      set title: 'eido', fullscreen: true
      set background: [0.05, 0.05, 0.12]

      on :key_down do |event|
        close if %w[escape q].include?(event.key)
      end

      scene = nil

      update do
        scene ||= Scene.new(Window.width, Window.height)
        scene.update
      end

      show
    end
  end
end
