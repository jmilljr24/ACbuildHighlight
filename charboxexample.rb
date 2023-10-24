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
  def initialize(page)
    super()
    @canvas = page.canvas(type: :overlay)
    @all_text = []
    @parts = {}
  end

  def show_text(str)
    begin
      @parts[str.select.with_index { |_, i| i.even? }.join] = str
    rescue StandardError
      nil
    end
    boxes = decode_text_with_positioning(str)
    return if boxes.string.empty?

    @all_text << boxes
  end

  def highlight
    @all_text.each do |boxes|
      @canvas.line_width = 0.5
      @canvas.stroke_color(0, 224, 0)
      @canvas.polyline(*boxes.lower_left, *boxes.lower_right,
                       *boxes.upper_right, *boxes.upper_left).close_subpath.stroke
    end
  end
  alias show_text_with_positioning show_text
end

doc = HexaPDF::Document.open('06_10.pdf')
doc.pages.each_with_index do |page, index|
  puts "Processing page #{index + 1}"
  processor = ShowTextProcessor.new(page)
  page.process_contents(processor)
  processor.highlight
end
doc.write('charboxexample.pdf', optimize: true)
