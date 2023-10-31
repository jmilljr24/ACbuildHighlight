# str = ['VS', -12.489, '-', 12.479, '1', -8.098, '0', 4.712,
#        '1', -8.098, '4']

# part = 'VS-1014'
# @part_location = []
# part_arr = part.split('')

# @str_search = []

def deep_copy(o) # copy hash
  Marshal.load(Marshal.dump(o))
end

def find_matching_part(str, part) # rubocop: disable Metrics
  @locations = {}
  @part_location = []
  @str_search = []
  str.each_with_index do |string, index|
    @str_search << [string, index]
    # @part_location << index
    next unless @str_search.length > (part.length * 2)

    @str_search.shift
    # @part_location.shift

    group = @str_search.select.with_index { |_, i| i.even? }
    begin
      # p @part_location if word.match(/#{part}/)
      word = []
      group.each { |l| word << l[0] }
      if word.join.match(part) && word[0] != ' '
        target = deep_copy(@str_search)
        @locations[str] = [] if @locations[str].nil?
        @locations[str].push(target.flat_map { |a| a[0] }) # remove index from nested array and flatten
      end
    rescue StandardError
      puts 'Could not find'
    end
  end
  @locations
end
