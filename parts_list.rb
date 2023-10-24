require 'csv'

module SectionParts
  file = CSV.read('rv10section4parts.csv')
  parts = []
  file.each { |c| parts << c[0] }
  define_method(:getParts) { parts }
end
