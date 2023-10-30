str = ['VS', -12.489, '-', 12.479, '1', -8.098, '0', 4.712,
       '1', -8.098, '4']

part = 'VS-1014'
@part_location = []
part_arr = part.split('')

@str_search = []

def find_matching_part(str, part) # rubocop:disable Metrics/AbcSize
  @part_location = []
  @str_search = []
  str.each_with_index do |string, index|
    @str_search << string
    @part_location << index
    next unless @str_search.length > (part.length * 2)

    @str_search.shift
    @part_location.shift

    word = @str_search.select.with_index { |_, i| i.even? }.join
    begin
      # p @part_location if word.match(/#{part}/)
      p @part_location if word.match(part) && word[0] != ' '
    rescue StandardError
      puts 'Could not find'
    end
  end
end
