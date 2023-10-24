require 'hexapdf'
require_relative 'parts_list'

class FindTextProcessor < HexaPDF::Content::Processor
  include SectionParts

  attr_accessor :page_parts

  def initialize(page)
    super()
    @canvas = page.canvas(type: :overlay)
    # @parts = %w[F-1006C F-1012A F-1006D F-1006B F-1032L F-1011C F-1029-L F-1010C
    #             F-1010A F-1011E F-1012E F-1010C F-1010 F-1011 F-1011A
    #             F-1010C-R F-1010C-L F-1007-L]
    @parts = getParts
    @page_parts = []
  end

  def show_text(str)
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

      b = part.split(' ')
      b.each do |word|
        @page_parts << part if @parts.include?(word)
      end
    end
  end
  alias show_text_with_positioning show_text
end
