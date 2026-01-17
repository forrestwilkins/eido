# TODO: Ensure smooth transitions between colors
# The following is just for testing out Ruby2D

require 'ruby2d'

@background_color = [1, 1, 1, 1]
@triangle_color1 = [1, 0, 0, 1]
@triangle_color2 = [0, 1, 0, 1]
@triangle_color3 = [0, 0, 1, 1]

set title: 'eido', background: @background_color

@triangle = Triangle.new(
  x1: 320, y1:  50,
  x2: 540, y2: 430,
  x3: 100, y3: 430,
  color: [@triangle_color1, @triangle_color2, @triangle_color3]
)

update do
  @background_color = [rand(0..1), rand(0..1), rand(0..1), 1]
  set background: @background_color

  @triangle_color1 = [rand(0..1), rand(0..1), rand(0..1), 1]
  @triangle_color2 = [rand(0..1), rand(0..1), rand(0..1), 1]
  @triangle_color3 = [rand(0..1), rand(0..1), rand(0..1), 1]
  @triangle.color = [@triangle_color1, @triangle_color2, @triangle_color3]
end

show
