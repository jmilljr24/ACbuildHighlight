#
# Usage:
# : `ruby show_char_boxes.rb INPUT.PDF`
#
require 'pry-byebug'
require 'hexapdf'
require_relative 'find_text'
require_relative 'parts_list'

class ShowTextProcessor < HexaPDF::Content::Processor
  include SectionParts
  attr_accessor :page_number, :color_key, :prev_parts, :prev_color, :used_colors, :text_box_parts
  attr_reader :boxes, :current_page_parts, :page_parts

  def initialize(page, page_number, prev_parts, page_parts, text_box_parts)
    super()
    @canvas = page.canvas(type: :overlay)
    # @parts = %w[F-1006C F-1012A F-1006D F-1006B F-1032L F-1011C F-1029-L F-1010C
    #             F-1010A F-1011E F-1012E F-1010C F-1010 F-1011 F-1011A
    #             F-1010C-R F-1010C-L F-1007-L]
    @parts = getParts
    @colors = %w[cyan darkgreen gold deeppink olivedrab paleturquoise red green blue orange]
    @color_key = {}
    @color_key = color_key
    @prev_parts = prev_parts
    @page_number = page_number
    @color_key['Page Number'] = @page_number
    @boxes = []
    @page_parts = page_parts
    @current_page_parts = []
    @text_box_parts = text_box_parts
  end

  def show_text(str) # rubocop:disable Metrics/
    begin
      # part = str.scan(/[-\w+]/).join # Converts utf-8 str to text string
      part = str.select.with_index { |_, i| i.even? }.join
    rescue StandardError
      nil
    end
    return unless @page_parts.include?(part) || # do nothing if part is not on current page
                  @text_box_parts&.flat_map do |map|
                    map[1]
                  end&.include?(part)

    # if @color_key.key?(part)
    if @text_box_parts&.flat_map { |map| map[1] }&.include?(part)
      # do stuff
      @parts.each do |part_number|
        color = nil
        positions = part.enum_for(:scan, /#{part_number}/).map { Regexp.last_match.begin(0) }
        next if positions.empty?

        if @color_key.key?(part_number)
          color = @color_key[part_number]
          @color_key[part_number] = color
        else
          key_color(part_number, nil)
        end
        boxes = decode_text_with_positioning(str)

        @text_box = [boxes.cut(positions[0], (positions[0] + part_number.length))]
        @text_box[0]&.each do |box|
          x, y = *box.lower_left
          tx, ty = *box.upper_right
          @canvas.fill_color(@color_key[part_number]).opacity(fill_alpha: 0.5)
                 .rectangle(x, y, tx - x, ty - y).fill
        end
      end
    else
      unless @color_key.key?(part)
        # do other stuff
        key_color(part, str)
      end
      @boxes << decode_text_with_positioning(str) # set boxes to str in color hash

    end

    # return if @boxes.string.empty?
    nil unless @text_box_parts&.flat_map { |map| map[0] }&.include?(part) # do nothing if part is not on current page

    # nil unless @text_box_parts&.key?(part) # value?

    # @text_box_parts[part].each do |h|
    #   # next unless h[0] == str
    #   index = h[1][0]
    #   @boxes << decode_text_with_positioning(index)
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

  def key_color(part, _str)
    n = @color_key.values
    n.each_with_index do |color, index|
      next if index == 0
      next if color.nil?

      @used_colors << color[0] unless @used_colors.include?(color)
    end
    color = @used_colors.empty? ? @colors.sample : (@colors - @used_colors).sample
    @color_key[part] = color
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
        box_fill(text_box, @color_key.dig(part.join))
      rescue StandardError
        box_fill(text_box, 'yellow') # set yellow if all colors used already
      end
    end
  end
  alias show_text_with_positioning show_text
end
@prev_color = nil
@color_key = {}
@prev_parts = nil
@used_colors = []

def deep_copy(o) # copy hash
  Marshal.load(Marshal.dump(o))
end
# doc = HexaPDF::Document.open(ARGV.shift)
# doc = HexaPDF::Document.open('06_10.pdf')
doc = HexaPDF::Document.open('no_first_page.pdf')

doc.pages.each_with_index do |page, index| # rubocop:disable Metrics/BlockLength
  puts "Processing page #{index + 1}"
  processor = FindTextProcessor.new(page)
  page.process_contents(processor)
  page_parts = processor.page_parts
  text_box_parts = processor.text_box_parts
  both_pages = @prev_parts & page_parts
  until both_pages == false || both_pages.empty?
    both_pages.each_with_index do |b, i|
      @color_key[b] = @prev_color[b]
      @used_colors << @color_key.dig(b)
      if i == both_pages.count - 1
        both_pages.clear
        @prev_parts.clear
      end
    end
  end
  processor = ShowTextProcessor.new(page, index, @prev_parts, page_parts, text_box_parts)
  processor.used_colors = @used_colors
  processor.color_key = @color_key
  page.process_contents(processor)
  processor.text_highlight
  @prev_color&.clear #  clear if not nil
  @prev_color = deep_copy(processor.color_key) # Create new hash with deep copy of previous hash(@color_key)
  @prev_parts&.clear
  @used_colors.clear
  @color_key.clear
  @prev_parts = processor.page_parts.uniq
end
doc.write('show_char_boxes.pdf', optimize: true)
