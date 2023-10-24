require 'hexapdf'

class FindTextProcessor < HexaPDF::Content::Processor
  attr_accessor :page_parts

  def initialize(page)
    super()
    @canvas = page.canvas(type: :overlay)
    @parts = %w[F-1006C F-1012A F-1006D F-1006B F-1032L F-1011C F-1029-L F-1010C
                F-1010A F-1011E F-1012E F-1010C F-1010 F-1011 F-1011A
                F-1010C-R F-1010C-L F-1007-L]
    @page_parts = []
  end

  def show_text(str)
    begin
      part = str.scan(/[-\w+]/).join # Converts utf-8 str to text string
    rescue StandardError
      puts 'invalid string'
    end
    return unless @parts.include?(part) # do nothing if part is not on current page

    @page_parts << part
  end
  alias show_text_with_positioning show_text
end
