require 'rexml/document'
require 'test/unit'

module ImportHelper
  extend Test::Unit::Assertions
  
  def ImportHelper.generate_query_variations(query)
    variations = [query]

    # Do not generate variations for long queries.
    if query.split(/ /).size <= 4
      variations = extend_variations(variations) do |var|
        # Generate variations where each term has punctuation removed. Currently 
        # we try removing single quote, double quote, period, dash, colon, and forward slash.
        generate_variations(var) { |term| term.gsub(/['\"\.\-\:\/]/, '') }
      end
      
      variations = extend_variations(variations) do |var|
        # Generate variations where pairs of adjacent terms are combined.
        generate_combined_term_variations(var)
      end

      variations = extend_variations(variations) do |var|
        # Generate variations where each term is pluralized.
        generate_variations(var) { |term| term.pluralize }    
      end
      
    end
  
    variations
  end
  
  # Extend the provided list of variations by running the block on each variation in the provided list.
  # The block takes a query as a parameter and returns an array of variations.
  def ImportHelper.extend_variations(variations) 
    temp_variations = []
    variations.each do |var|
      temp_variations += yield var
    end  
    variations += temp_variations
  end
  
  # Generate query variations where a block is applied to each term in the query.
  # The block receives the term as a parameter and the return value of the block replaces the term.
  def ImportHelper.generate_variations(query)
    variations = []
    
    terms = query.split(/ /)
    
    for i in 0 ... terms.size
      left = terms[0 ... i]
      mid = yield terms[i]
      if mid != terms[i]
        # Currently we try removing single quote, double quote, period, dash, colon, forward slash
        right = terms[i+1 ... terms.size]
        variations << (left + [mid] + right).join(' ')
      end
    end
    
    variations
  end
  
  # Generate query variations where a block is applied to each term in the query.
  # The block receives the term as a parameter and the return value of the block replaces the term.
  # This version generates more variations than the above version, because it includes variations where the block
  # is applied to more than a single term in the query. It takes considerably longer for a large
  # dataset and yields only a marginal improvement in the number of variations that are pruned.
  # The small size of the improvement is partly due to the way gather_variation_infos is able to link
  # variations that differ in multiple terms, provided a series of intermediate forms exists
  # in the dataset, and each intermediate form differs from the previous form only in a single term.
  def ImportHelper.generate_all_variations(query)
    variations = []
    
    terms = query.split(/ /)
    
    terms.each do |term|
      varied_term = yield term

      new_variations = []

      if variations.empty?
        new_variations << term
        if varied_term != term
          new_variations << varied_term
        end
      else
        variations.each do |var| 
          new_variations << [var, term].join(' ')
          if varied_term != term
            new_variations << [var, varied_term].join(' ')
          end
        end        
      end
      
      variations = new_variations
    end
    
    variations
  end

  # Generate query variations where each pair of adjacent terms is combined into a single term.
  # Note that for a given variation, only a single pair of terms will be combined.
  # E.g. for the query "lap top soft case" we will generate the variations "laptop soft case",  
  # "lap topsoft case", and "lap top softcase", but not "laptop softcase". As in the case of 
  # generate_all_variations (see comments for that method), there would likely be only marginal
  # improvement in number of queries pruned if we allowed combining multiple pairs.
  def ImportHelper.generate_combined_term_variations(query)
    variations = []
    terms = query.split(/ /)
    for i in 0 ... (terms.size - 1)
      left = terms[0 ... i]
      combined = [terms[i], terms[i+1]].join 
      right = terms[i+2 ... terms.size]
      variations << (left + [combined] + right).join(' ')
    end
    variations
  end
  
  # Recursively find all variations of a given info that actually exist in the dataset.
  # Parameters: 
  #   info: The info whose variations are to be found
  #   infos_by_variation: Hash from query variation to array of matching infos
  #   info_array: The accumulated array of variations.
  def ImportHelper.gather_variation_infos(info, infos_by_variation, info_array)
    # Avoid cycles.
    if info_array.find { |an_info| an_info.equal?(info) }.nil?
      info_array << info
      if not info[:variations].nil?
        info[:variations].each do |variation|
          infos = infos_by_variation[variation]
          if not infos.nil?
            infos.each do |an_info|
              gather_variation_infos(an_info, infos_by_variation, info_array)
            end
          end
        end
      end
    end
  end
  
  # Prune queries which are less common variations of another query in the hash.
  # Input is either an array of query info hashes like {query: query string, count: count},
  # or a hash of the form {"query string" => {query: "query string", count: count}}
  # Returns the pruned array of query info hashes.
  def ImportHelper.prune_queries(input_queries)
    queries = {}
    # Copy infos since we are going to modify them.
    if input_queries.is_a? Hash
      input_queries.each_pair do |query, info| 
        queries[query] = info.clone
      end
    else
      input_queries.each do |info|
        queries[info[:query]] = info.clone
      end
    end
    
    pruned_queries = []
    
    # Create a hash where keys are all variations found and values are arrays of query info hashes that 
    # match that variation.
    # Note that the keys of the hash include queries which may not exist in the dataset. This allows
    # matching of queries indirectly (e.g. when one of query A's variations matches one of query B's variations).
    infos_by_variation = {}
    
    queries.each_pair do |query, info| 
      variations = generate_query_variations(query)
      info[:variations] = variations
      variations.each do |variation|
        if infos_by_variation[variation].nil?
          infos_by_variation[variation] = [info]
        else
          infos_by_variation[variation] << info
        end
      end
    end
    
    while not queries.empty?
      query = queries.first[0]
      info = queries.first[1]
      # Recursively find all variations that actually exist in the dataset.
      variation_infos = []
      gather_variation_infos(info, infos_by_variation, variation_infos)
      # Find variation with largest count
      most_frequent_variation = nil
      total_count = 0
      variation_infos.each do |variation_info|
        queries.delete(variation_info[:query])
        total_count += variation_info[:count]
        if most_frequent_variation.nil? or variation_info[:count] > most_frequent_variation[:count]
          most_frequent_variation = variation_info
        end
      end
      # Store the info for the most frequent variation
      pruned_queries << {query: most_frequent_variation[:query], count: total_count}
    end
    pruned_queries
  end       
  
  # Process a line in the file and create a query info hash of the form {query: query, count: count}.
  def ImportHelper.extract_query_info(line)
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

      # Unescape XML escape sequences
      query = REXML::Text::unnormalize(query)

      query.downcase!
      
      # Remove certain punctuation characters
      query.gsub!(/[\*\\]/, '')
              
      # Replace sequences of spaces and commas with a single space.
      query.gsub!(/[ \,]+/, ' ')
      
      query.strip!
      
      count = REXML::Text::unnormalize(fields[4]).gsub(',', '').to_i
      
      if not query.empty? and count > 0
        # Skip queries that consist only of numbers (e.g. lists of skus)
        if not query =~ /^[0-9 ]+$/
          return {query: query, count: count}
        end
      end
    end
    nil
  end
  
  # Basic tests for query import.
  def ImportHelper.run_tests
    # Verify line processing
    
    # Verify queries consisting only of numbers are skipped
    query = extract_query_info('77.,,101 102 224 999,,"40,791",,,0.1%')
    assert_nil query
    
    # Verify handling of XML escape sequences.
    # Verify handling of count with comma.
    query = extract_query_info('77.,,a very harold &#38; kumar christmas,,"40,791",,,0.1%')
    assert_not_nil query
    assert_equal "a very harold & kumar christmas", query[:query]
    assert_equal 40791, query[:count]
    
    # Verify handling of query with comma.
    # Verify removal of extra spaces between query terms.
    # Verify downcasing of query.
    # Verify stripping leading and trailing spaces.
    query = extract_query_info('77.,,"  Query  with , comma  ",,"40,791",,,0.1%')
    assert_not_nil query
    assert_equal "query with comma", query[:query]
    assert_equal 40791, query[:count]

    # Verify removal of unwanted punctuation.
    query = extract_query_info('77.,,unwanted *\ punctuation,,"40,791",,,0.1%')
    assert_not_nil query
    assert_equal "unwanted punctuation", query[:query]
    assert_equal 40791, query[:count]

    # Verify word combining
    queries = [{query: "laptop", count: 5}, {query: "lap top", count: 6}]
    results = prune_queries(queries)
    assert_equal 1, results.size
    assert_equal "lap top", results[0][:query]
    assert_equal 11, results[0][:count]
    
    # Order of queries in the list should not matter.
    queries = [{query: "lap top", count: 6}, {query: "laptop", count: 5}]
    results = prune_queries(queries)
    assert_equal 1, results.size
    assert_equal "lap top", results[0][:query]
    assert_equal 11, results[0][:count]
    
    # The variation with the higher count should always win.
    queries = [{query: "lap top", count: 5}, {query: "laptop", count: 6}]
    results = prune_queries(queries)
    assert_equal 1, results.size
    assert_equal "laptop", results[0][:query]
    assert_equal 11, results[0][:count]

    # Verify pluralization
    queries = [{query: "foxes", count: 5}, {query: "fox", count: 6}]
    results = prune_queries(queries)
    assert_equal 1, results.size
    assert_equal "fox", results[0][:query]
    assert_equal 11, results[0][:count]

    # Verify word combining with punctuation.
    # Verify more than two variations.
    queries = [{query: "a-b", count: 1}, 
               {query: "a:b", count: 1},
               {query: "a/b", count: 1},
               {query: "a'b", count: 1}, 
               {query: "a\"b", count: 1},
               {query: "a.b", count: 1},
               {query: "ab", count: 2}]
    results = prune_queries(queries)
    assert_equal 1, results.size
    assert_equal "ab", results[0][:query]
    assert_equal 8, results[0][:count]
        
    # Verify with multiple varying terms
    queries = [{query: "brown laptops bag", count: 5}, {query: "brown laptop bags", count: 6}]
    results = prune_queries(queries)
    assert_equal 1, results.size
    assert_equal "brown laptop bags", results[0][:query]
    assert_equal 11, results[0][:count]
    
    queries = [{query: "laptop", count: 6}, {query: "laptops", count: 5}, {query: "laptop sleeve", count: 4}]
    results = prune_queries(queries)
    assert_equal 2, results.size
    results_hash = {}
    results.each { |info| results_hash[info[:query]] = info }
    assert_not_nil results_hash["laptop"]
    assert_equal 11, results_hash["laptop"][:count]
    assert_not_nil results_hash["laptop sleeve"]
    assert_equal 4, results_hash["laptop sleeve"][:count]
   
    # Verify that when neither query is a direct variation of the other, we still detect
    # that they are one-step-removed variations.
    queries = [{query: "laptop", count: 5}, {query: "lap tops", count: 6}]
    results = prune_queries(queries)
    assert_equal 1, results.size
    assert_equal "lap tops", results[0][:query]
    assert_equal 11, results[0][:count]
    
    # Verify hash form of input to prune_queries.
    queries = {"laptop" => {query: "laptop", count: 5}, "lap top" => {query: "lap top", count: 6}}
    results = prune_queries(queries)
    assert_equal 1, results.size
    assert_equal "lap top", results[0][:query]
    assert_equal 11, results[0][:count]
  end
end

desc "Tests for import_bb_searches"
task :test_import_searches => :environment do
  begin 
    ImportHelper.run_tests
    puts "Tests completed successfully"
  rescue Exception => e
    puts "Error in tests: #{e} at #{e.backtrace.find { |location| location.include? __FILE__ }}"
  end
end

desc "Import previous searches from BestBuy CSV file to keyword_searches table"
task :import_bb_searches, [:filename] => :environment do |t, args|
  if args[:filename].nil?
    puts "Usage: rake import_bb_searches <CSV file>"
    next
  end
  
  filename = args[:filename]
  puts "Import BB searches, file = #{filename}"
  
  queries = {}
  
  # Load all the queries from the file
  File::open(filename) do |file|
    file.each_line do |line|
      
      query = ImportHelper.extract_query_info(line)
      
      if not query.nil? and queries[query[:query]].nil?
        queries[query[:query]] = query
      end
    end
  end

  puts "Pruning queries ..."
    
  # Prune queries which are less common variations of another query.
  pruned_queries = ImportHelper.prune_queries(queries)

  puts "Importing queries ..."
  
  searches_to_save = []
  
  query_count = 0

  # Import the queries in to the database.
  pruned_queries.each_with_index do |query_info, index|      
    query = query_info[:query]
    count = query_info[:count]
     
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
    if searches_to_save.size >= 10000 or (index == pruned_queries.size - 1)
      KeywordSearch.import(searches_to_save, :on_duplicate_key_update => [:count])
      searches_to_save = []
      puts "Imported #{query_count} queries"
    end
  end
  
  puts "Reindexing Solr ..."
  KeywordSearch.solr_reindex(batch_size: 500)
  
  puts "Done, total queries imported: #{query_count}"
end
