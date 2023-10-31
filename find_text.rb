require 'hexapdf'
require_relative 'parts_list'
require_relative 'string_search'

class FindTextProcessor < HexaPDF::Content::Processor
  include SectionParts

  attr_accessor :page_parts, :text_box_parts

  def initialize(page)
    super()
    @canvas = page.canvas(type: :overlay)
    # @parts = %w[F-1006C F-1012A F-1006D F-1006B F-1032L F-1011C F-1029-L F-1010C
    #             F-1010A F-1011E F-1012E F-1010C F-1010 F-1011 F-1011A
    #             F-1010C-R F-1010C-L F-1007-L]
    @parts = getParts
    @page_parts = []
    @text_box_parts = []
  end

  def show_text(str) # rubocop:disable Metrics/
    begin
      # part = str.scan(/[-\w+]/).join # Converts utf-8 str to text string
      part = str.select.with_index { |_, i| i.even? }.join
    rescue StandardError
      nil
    end
    if @parts.include?(part) # do nothing if part is not on current page
      @page_parts << part
    else
      return if part.nil?

      @parts.each do |part_number|
        unless part.enum_for(:scan, /#{part_number}/).map { Regexp.last_match.begin(0) }.empty?
          @page_parts << part_number # just the part number is added
          @text_box_parts << [part_number, part] # this is a text line string containing the part
        end
      end
      # return if part.nil?

      # b = part.split(' ')
      # b.each do |word|
      #   @text_box_parts[word] = find_matching_part(str, word) if @parts.include?(word)
      #   # @page_parts << part if @parts.include?(word)
      # end
    end
  end
  alias show_text_with_positioning show_text
end
