# # Show Character Bounding Boxes
#
# This examples shows how to process the contents of a page. It finds all
# characters on a page and surrounds them with their bounding box. Additionally,
# all consecutive text runs are also surrounded by a box.
#
# The code provides two ways of generating the boxes. The commented part of
# `ShowTextProcessor#show_text` uses a polyline since some characters may be
# transforemd (rotated or skewed). The un-commented part uses rectangles which
# is faster and correct for most but not all cases.
#
# Usage:
# : `ruby show_char_boxes.rb INPUT.PDF`
#

require 'hexapdf'

class ShowTextProcessor < HexaPDF::Content::Processor
  attr_accessor :parts

  def initialize(page)
    super()
    @canvas = page.canvas(type: :overlay)
    @all_text = []
    @text_box = []
    @parts = %w[ VS-1014 F-1006C F-1012A F-1006D F-1006B F-1032L F-1011C F-1029-L F-1010C
                 F-1010A F-1011E F-1012E F-1010C F-1010 F-1011 F-1011A
                 F-1010C-R F-1010C-L F-1007-L VS-1014-R VS-1014-L]
    @boxes = nil
    @text = {}
  end

  def show_text(str) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    # test = decode_text_with_positioning(['T', 8.44, 'ri', 4.049, 'm '])
    begin
      part_number_string = str.select.with_index { |_, i| i.even? }.join
      @text[part_number_string] = str
    rescue StandardError
      nil
    end
    boxes = decode_text_with_positioning(str)
    return if boxes.string.empty?

    @all_text << boxes
    return if part_number_string.nil?

    return unless part_number_string.split(' ').count > 1

    @parts.each do |part_number|
      positions = part_number_string.enum_for(:scan, /#{part_number}/).map { Regexp.last_match.begin(0) }
      # positions unless positions.empty?
      return unless part_number == 'VS-1014'

      @text_box << boxes.cut(74, 81)
      @text_box[0]&.each do |box|
        x, y = *box.lower_left
        tx, ty = *box.upper_right
        @canvas.fill_color('red').opacity(fill_alpha: 0.5)
               .rectangle(x, y, tx - x, ty - y).fill
      end
    end

    # return unless part_number == 'VS-1014'

    # boxes.split(74...81)
    # p boxes
  end

  def highlight
    @all_text.each do |boxes|
      # p boxes[0]
      @canvas.line_width = 0.5
      @canvas.stroke_color(0, 224, 0)
      @canvas.polyline(*boxes.lower_left, *boxes.lower_right,
                       *boxes.upper_right, *boxes.upper_left).close_subpath.stroke
    end
    @text_box.each do |boxes|
      # p boxes[0]
      @canvas.line_width = 0.5
      @canvas.stroke_color(224, 0, 0)
      @canvas.polyline(*boxes.lower_left, *boxes.lower_right,
                       *boxes.upper_right, *boxes.upper_left).close_subpath.stroke
    end
  end

  def my_decode(str)
    @boxes = decode_text_with_positioning(str)
  end
  alias show_text_with_positioning show_text
end

doc = HexaPDF::Document.open('no_first_page.pdf')
doc.pages.each_with_index do |page, index|
  puts "Processing page #{index + 1}"
  processor = ShowTextProcessor.new(page)
  page.process_contents(processor)
  # processor.highlight
end
doc.write('charboxexample.pdf', optimize: true)
