require 'hexapdf'
require_relative 'parts_list'
# require_relative 'string_search'

class StringBoxesProcessor < HexaPDF::Content::Processor
  include SectionParts

  attr_accessor :page_parts, :text_box_parts, :str_boxes

  def initialize(page)
    super()
    @canvas = page.canvas(type: :overlay)
    # @parts = %w[F-1006C F-1012A F-1006D F-1006B F-1032L F-1011C F-1029-L F-1010C
    #             F-1010A F-1011E F-1012E F-1010C F-1010 F-1011 F-1011A
    #             F-1010C-R F-1010C-L F-1007-L]
    @parts = getParts
    @str_boxes = {}
    @page_parts = {}
  end

  def show_text(str) # /
    @str_boxes[str] = decode_text_with_positioning(str)
  end
  alias show_text_with_positioning show_text

  def match(string_boxes)
    string_boxes.each do |string, value|
      begin
        part = string.select.with_index { |_, i| i.even? }.join
      rescue StandardError
        nil
      end
      # if @parts.include?(part)
      #   @page_parts[string] = [] unless @page_parts.key?(string)
      #   @page_parts[string].push(value)
      # else
      @parts.each do |part_number|
        positions = part&.enum_for(:scan, /#{part_number}/)&.map { Regexp.last_match.begin(0) }
        next if positions.nil? || positions.empty?

        positions.each do |pos|
          @page_parts[string] = [] unless @page_parts.key?(string)

          @page_parts[string].push(value.cut(pos, (pos + part_number.length)))
        end
      end
      # end
    end
  end

  def color(encodes)
    encodes.each do |_string, boxes|
      boxes.each do |b|
        b.each do |box|
          x, y = *box.lower_left
          tx, ty = *box.upper_right
          @canvas.fill_color('yellow').opacity(fill_alpha: 0.5)
                 .rectangle(x, y, tx - x, ty - y).fill
        end
      end
    end
  end
end

doc = HexaPDF::Document.open('no_first_page.pdf')

doc.pages.each_with_index do |page, index|
  puts "Processing page #{index + 1}"
  processor = StringBoxesProcessor.new(page)
  page.process_contents(processor)
  str_boxes = processor.str_boxes
  processor.match(str_boxes)
  page_parts = processor.page_parts
  processor.color(page_parts)
end
doc.write('show_char_boxes.pdf', optimize: true)
