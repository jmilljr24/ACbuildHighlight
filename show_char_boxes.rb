#
# Usage:
# : `ruby show_char_boxes.rb INPUT.PDF`
#
require 'pry-byebug'
require 'hexapdf'

class ShowTextProcessor < HexaPDF::Content::Processor
  attr_accessor :page_number, :color_key, :prev_parts, :prev_color
  attr_reader :boxes

  def initialize(page, page_number, prev_parts = nil, prev_color = nil, color_key = {})
    super()
    # @text_list_arr = text_list
    @canvas = page.canvas(type: :overlay)
    @parts = %w[F-1006C F-1012A F-1006D F-1006B F-1032L F-1011C F-1029-L F-1010C
                F-1010A F-1011E F-1012E F-1010C F-1010 F-1011 F-1011A
                F-1010C-R F-1010C-L F-1007-L]
    @colors = %w[cyan darkgreen gold deeppink olivedrab paleturquoise red green blue orange]
    @color_key = color_key
    @prev_parts = prev_parts
    @prev_color = prev_color
    @page_number = page_number
    @color_key['Page Number'] = @page_number
    @used_colors = []
    @boxes = []
    @part = nil
  end

  def show_text(str)
    begin
      p part = str.scan(/[-\w+]/).join # Converts utf-8 str to text string
    rescue StandardError
      puts 'invalid string'
    end
    return unless @parts.include?(part) # do nothing if part is not on current page

    # check if part was on previous page
    @color_key[part] = @prev_color.delete(part) if !@prev_parts.nil? and @prev_parts.include?(part) # rubocop:disable Style/AndOr

    key_color(part, str) unless @color_key.key?(part) # return if part/color pair is in hash

    @boxes << decode_text_with_positioning(@color_key.dig(part, 1)) # set boxes to str in color hash
    # return if @boxes.string.empty?

    # begin
    #   box_fill(@boxes, @color_key.dig(part, 0))
    # rescue StandardError
    #   box_fill(@boxes, 'yellow') # set yellow if all colors used already
    # end
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
    # color = @colors.pop
    n = @color_key.values
    n.each_with_index do |color, index|
      next if index == 0

      @used_colors << color[0]
    end
    color = @used_colors.empty? ? @colors.sample : (@colors - @used_colors).sample
    @color_key[part] = [color, str]
  end

  def text_highlight
    @boxes.each do |text_box|
      part = []
      i = 0
      text_box.each do
        part << text_box[i].string
        i += 1
      end
      begin
        box_fill(text_box, @color_key.dig(part.join, 0))
      rescue StandardError
        box_fill(text_box, 'yellow') # set yellow if all colors used already
      end
    end
  end
  alias show_text_with_positioning show_text
end
@prev_color = nil
@color_key = nil
@prev_parts = nil
# doc = HexaPDF::Document.open(ARGV.shift)
doc = HexaPDF::Document.open('ocr.pdf')

doc.pages.each_with_index do |page, index|
  puts "Processing page #{index + 1}"
  @prev_parts = @prev_color.keys unless @prev_color.nil?
  processor = ShowTextProcessor.new(page, index, @prev_parts, @prev_color)
  # binding.pry
  page.process_contents(processor)
  @prev_color&.clear #  clear if not nil
  @prev_color = processor.color_key
  processor.text_highlight
end
doc.write('show_char_boxes.pdf', optimize: true)
