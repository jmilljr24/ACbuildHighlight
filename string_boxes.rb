require 'hexapdf'
require_relative 'parts_list'
# require_relative 'string_search'

class StringBoxesProcessor < HexaPDF::Content::Processor
  include SectionParts

  attr_accessor :page_parts, :text_box_parts, :str_boxes, :used_colors

  def initialize(page, used_colors = [])
    super()
    @canvas = page.canvas(type: :overlay)
    # @parts = %w[F-1006C F-1012A F-1006D F-1006B F-1032L F-1011C F-1029-L F-1010C
    #             F-1010A F-1011E F-1012E F-1010C F-1010 F-1011 F-1011A
    #             F-1010C-R F-1010C-L F-1007-L]
    @colors = %w[cyan darkgreen gold deeppink olivedrab paleturquoise red green blue orange]
    @used_colors = used_colors
    @parts = getParts
    @str_boxes = {}
    @page_parts = {}
    @color_key = {}
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
          @page_parts[string] = {} unless @page_parts.key?(string)
          @page_parts[string][part_number] = [] unless @page_parts[string].key?(part_number)

          @page_parts[string][part_number].push(value.cut(pos, (pos + part_number.length)))
        end
      end
      # end
    end
  end

  #   def assign_color(list)
  #     p = []
  #
  #     list.each do |_key, value|
  #       value.each do |k, _v|
  #         p << k
  #       end
  #     end
  #     unique_parts = p.uniq
  #     unique_parts.each do |part|
  #       @colors.each do |color|
  #         next if @color_key.values.include?(color)
  #
  #         break @color_key[part] = color
  #       end
  #     end
  #   end
  #
  def assign_color(list)
    p = []

    list.each do |_key, value|
      value.each do |k, _v|
        p << k
      end
    end
    unique_parts = p.uniq
    unique_parts.each do |part|
      n = @color_key.values
      n.each_with_index do |color, _index|
        # next if index == 0 # this was for skipping the page number if implemented
        next if color.nil?

        @used_colors << color unless @used_colors.include?(color)
      end
      color = @used_colors.empty? ? @colors.sample : (@colors - @used_colors).sample
      @color_key[part] = color
    end
  end

  def color(encodes)
    encodes.each do |_string, boxes|
      boxes.each_with_index do |a, _ai|
        # next if ai.zero?

        a.each_with_index do |b, bi|
          next if bi.zero?

          b.each do |c|
            c.each do |box|
              x, y = *box.lower_left
              tx, ty = *box.upper_right
              color = @color_key.dig(a[0]).nil? ? 'yellow' : @color_key.dig(a[0])
              @canvas.fill_color(color).opacity(fill_alpha: 0.5)
                     .rectangle(x, y, tx - x, ty - y).fill
            end
          end
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
  processor.assign_color(page_parts)
  processor.color(page_parts)
end
doc.write('show_char_boxes.pdf', optimize: true)
