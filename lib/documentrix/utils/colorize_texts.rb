require 'term/ansicolor'
require 'kramdown/ansi'

# A utility class for colorizing and formatting text output with ANSI color
# codes and size information.
#
# The ColorizeTexts class takes a collection of text strings and formats them
# with dynamically generated ANSI colors for visual distinction. Each text
# block is wrapped to fit the terminal width and appended with its size in
# bytes, making it ideal for debugging text-splitting pipelines.
#
# @example
#   colorizer = Documentrix::Utils::ColorizeTexts.new('First chunk', 'Second chunk')
#   puts colorizer.to_s
class Documentrix::Utils::ColorizeTexts
  include Math
  include Term::ANSIColor
  include Kramdown::ANSI::Width

  # Initializes a new instance of ColorizeTexts.
  #
  # @param texts [String, Array<String>] a variable list of strings or an array
  #   of strings to be colorized.
  #
  # @return [Documentrix::Utils::ColorizeTexts] a new instance of ColorizeTexts
  def initialize(*texts)
    @texts = texts.flatten
  end

  # Returns a formatted string representation of the texts.
  #
  # Each text block is:
  # 1. Assigned a color from a trigonometric RGB gradient.
  # 2. Wrapped to 90% of the terminal width.
  # 3. Appended with its size in bold text.
  #
  # @return [String] the colorized and formatted output string.
  def to_s
    result = +''
    @texts.each_with_index do |t, i|
      color = colors[(t.hash ^ i.hash) % colors.size]
      wrap(t, percentage: 90).each_line { |l|
        result << on_color(color) { color(text_color(color)) { l } }
      }
      result << "\n##{bold{t.size.to_s}} \n\n"
    end
    result
  end

  private

  # Determines the optimal text color (black or white) for a given background
  # color to ensure maximum readability based on contrast.
  #
  # @param color [Symbol, Term::ANSIColor::Attribute] the ANSI color attribute
  #
  # @return [Array<String>] an array containing the RGB colors that provide
  #   the best contrast for black and white backgrounds.
  def text_color(color)
    color = Term::ANSIColor::Attribute[color]
    [
      Attribute.nearest_rgb_color('#000'),
      Attribute.nearest_rgb_color('#fff'),
    ].max_by { |t| t.distance_to(color) }
  end

  # Generates a 256-color RGB gradient using sine wave oscillations.
  #
  # @return [Array<Array<Integer>>] an array of 256 RGB color arrays,
  #   where each inner array contains [R, G, B] values from 0 to 255.
  def colors
    @colors ||= (0..255).map { |i|
      [
        128 + 128 * sin(PI * i / 32.0),
        128 + 128 * sin(PI * i / 64.0),
        128 + 128 * sin(PI * i / 128.0),
      ].map { _1.clamp(0, 255).round }
    }
  end
end
