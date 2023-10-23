#
# Usage:
# : `ruby show_char_boxes.rb INPUT.PDF`
#
require 'pry-byebug'
require 'hexapdf'

class ShowTextProcessor < HexaPDF::Content::Processor
  attr_accessor :page_number, :color_key, :prev_color_key

  def initialize(page, page_number, prev_color_key = nil, color_key = {}) # text_list = []
    super()
    # @text_list_arr = text_list
    @canvas = page.canvas(type: :overlay)
    @parts = %w[F1006C F1012A F1006D F1006B F1032L F1011C F1029L F1010C F1010A F1011E F1012E F1010C F1010 F1011 F1011A
                F1010CR F1010CL F1007L]
    @colors = %w[violet yellow maroon brown cyan darkgreen darkred gold deeppink olivedrab paleturquoise red green blue
                 orange]
    @color_key = color_key
    @prev_color_key = prev_color_key
    @page_number = page_number
    @color_key['Page Number'] = @page_number
  end

  def show_text(str)
    begin
      part = str.scan(/\w+/).join # Converts utf-8 str to text string
    rescue StandardError
      puts 'invalid string'
    end
    return unless @parts.include?(part) # do nothing if part is not on current page

    key_color(part, str) unless @color_key.key?(part) # return if part/color pair is in hash

    boxes = decode_text_with_positioning(@color_key.dig(part, 1)) # set boxes to str in color hash
    return if boxes.string.empty?

    begin
      box_fill(boxes, @color_key.dig(part, 0))
    rescue StandardError
      box_fill(boxes, 'yellow') # set yellow if all colors used already
    end
  end

  def box_fill(boxes, color)
    boxes.each do |box|
      x, y = *box.lower_left
      tx, ty = *box.upper_right
      @canvas.fill_color(color).opacity(fill_alpha: 0.5)
             .rectangle(x, y, tx - x, ty - y).fill
    end
  end

  def key_color(part, str)
    color = @colors.pop
    @color_key[part] = [color, str]
  end
  alias show_text_with_positioning show_text
end
@prev_color = nil
doc = HexaPDF::Document.open(ARGV.shift)
doc.pages.each_with_index do |page, index|
  puts "Processing page #{index + 1}"
  unless @prev_color.nil?
    parts = @prev_color.keys
    parts.each do |part|
      p part
      # p @prev_color_key[part] = @prev_color[part]
    end
  end
  processor = ShowTextProcessor.new(page, index)
  # binding.pry
  page.process_contents(processor)
  @prev_color = processor.color_key
end
doc.write('show_char_boxes.pdf', optimize: true)
