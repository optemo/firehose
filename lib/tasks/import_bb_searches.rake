require 'rexml/document'

desc "Import previous searches from BestBuy CSV file to keyword_searches table"
task :import_bb_searches, [:filename] => :environment do |t, args|
  if args[:filename].nil?
    puts "Usage: rake import_bb_searches <CSV file>"
    next
  end
  
  filename = args[:filename]
  puts "Import BB searches, file = #{filename}"
  
  query_count = 0
  File::open(filename) do |file|
    searches_to_save = []
    file.each_line do |line|
      
      # Find values in quotes
      while (match = line.match(/"[^"]*"/))
        # Comma is the field delimiter, but may also occur inside fields. When a comma occurs
        # inside a field, the field is quoted. We remove quotes and replace commas inside quotes 
        # with the corresponding XML escape sequence.
        line[match.begin(0) ... match.end(0)] = match[0].gsub(',', '&#44;').gsub('"', '')
      end
      
      fields = line.split ','
      if fields.size >= 5
        query = fields[2]

        query.strip!
                
        # Unescape XML escape sequences
        query = REXML::Text::unnormalize(query)

        query.downcase!
        
        count = REXML::Text::unnormalize(fields[4]).gsub(',', '').to_i
        
        if not query.empty? and count > 0
          query_count += 1
          # The database collation we are using causes queries that differ only by an accent
          # to be considered as matches. We have to manually filter those matches out.
          searches = KeywordSearch.find_all_by_query(query)
          search = searches.find { |item| item.query == query }
          if search.nil?
            search = KeywordSearch.new(query: query)
          end
          search.count = count
          searches_to_save << search
          if searches_to_save.size >= 10000
            KeywordSearch.import(searches_to_save, :on_duplicate_key_update => [:count])
            searches_to_save.each_slice(500) { |slice|
              Sunspot.index(slice)
            }
            Sunspot.commit
            searches_to_save = []
            puts "Imported #{query_count} searches"
          end
        end
      end
    end
  end
  puts "Done, total queries imported: #{query_count}"
end
