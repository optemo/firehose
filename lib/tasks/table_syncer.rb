#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# the amazing mysql table syncer! 
# this program syncs between two database tables to make a recipient match a donor table
# to use: define some database connections at the top of this file
# then run --help to see options
# See also http://code.google.com/p/ruby-roger-useful-functions/wiki/MysqlTableSyncer
# Note that it automatically creates would_has_run.sql which has the contents of what if would have executed, had you passed --commit
#
# Enjoy.
# Note that with ssh hosts if it fails to connect, it will try and auto-connect to that host.
# the "auto established" tunnel will then be running in the background.
# Re-run the script and it will hopefully work the second time.
# If it doesn't, then run the command output [it will print out the ssh tunnel command appropriate] in a different terminal window

# 2008 Roger Pack Public Domain
# No warranty expressed or implied of any type :)

  require 'rubygems'
  begin
	require 'mysqlplus' # it's barely faster
  rescue LoadError
	require "mysql"
  end
  require 'optparse'
 
  # define some databases and how you connect with them
  # replace with your own
  local_db = {:host => '127.0.0.1', :user => 'root', :password => '', :db => 'local_leadgen_dev'}

  # remote host that we'll use SSH tunnels for
  ties_db = {:user => 'db_user_name_ex_root', :password => 'mysql_password_for_that_user', :db => 'wilkboar_ties', :ssh_host => 'my_host.com', :ssh_user => 'ssh_login'} # ssh example -- no ssh password allowed [here], but it attempts to create an ssh tunnel for you to that host, whence you can enter one.
  # note: if you have multiple remote hosts then you'll want to assign a different port for each host via :tunnel_local_port_to_use

  # ex: I suppose you wouldn't need an ssh_user if you had pre-established the tunnel youself  [ex: if you had already created a tunnel on port 9000 to the remote Mysql port]
  ties_db_no_host_even = {:user => 'db_user_name_ex_root', :password => 'mysql_password_for_that_user', :db => 'wilkboar_ties', :tunnel_local_port_to_use => 9000} 

  # how to setup remote ports, custom ssh port, etc.
  ties_super_advanced = {:user => 'mysql_user', :password => 'mysql_pass_for_that_user', :ssh_host => 'helpme.com', :ssh_port => 888, :ssh_user => 'ssh_login_name', :ssh_local_to_host => '127.0.0.1 -- change if you want it to connect to a different host "from the remote"', :ssh_local_to_port => '4000 instead of the normal 3306'}
  # ssh_port is the ssh port [instead of 22] for the remote host

  # list of db's 
  all_database_names = ['local_db', 'ties_db', 'ties_db_no_host_even', 'ties_super_advanced'] # only used --help command is more useful and can print out the database connection names available -- not necessary


local_db1 = {:host => '127.0.0.1', :user => 'root', :password => 'zev', :db => 'firehose_dev_local'}
local_db2 = {:host => '127.0.0.1', :user => 'root', :password => 'zev', :db => 'firehose_development'}
dev = {:host => 'jaguar', :user => 'ray', :password => '1am@7Ysql', :db => 'firehose_development'}
prod = {:host => 'jaguar', :user => 'ray', :password => '1am@7Ysql', :db => 'firehose_test'}
linode1 = {:host => 'jaguar', :user => 'ray', :password => '1am@7Ysql', :db => 'firehose_test'}
linode2 = {:host => 'jaguar', :user => 'ray', :password => '1am@7Ysql', :db => 'firehose_test'}
  # here we'll setup defaults -- it will use these databases by default unless you specify otherwise on the command line [or use nil for none]
  my_options = {}
  db_from_name = 'local_db' # replace with yours
  db_to_name = 'local_db'
  actually_run_queries = false # default to just previewing -- force use --commit to actually run it
  verbose = true 
  default_tables_to_sync = nil # replace with default tables to sync, ex: ['users']
  my_options[:skip_the_warning_prompt_for_commit] = false
  auto_create_ssh_tunnels = true


  # now parse incoming options 
  tables_to_sync = nil # leave as nil--this will be propagated by the defaults, above, or those passed from the command line

  do_structure_sync_only = false

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] table names"

    opts.on("-f", "--from=FROM", "from database name #{all_database_names.inspect}") do |from_name|
      db_from_name = from_name
    end

    opts.on("-t", "--to=TO", "to database name #{all_database_names.inspect} \n\t\t\t\t\t\tedit databases descriptions at #{__FILE__}") do |to_name|
	db_to_name = to_name
    end

    opts.on('--verbose') do
	my_options[:verbose] = true
    end

    opts.on('-y', 'skip the warning prompt for commit') do
	my_options[:skip_the_warning_prompt_for_commit] = true
    end

    opts.on("-s", "--tables=", "tables list comma separated, ex --tables=table_one,table_two -- or if you'd just like to do all tables, then do --tables=ALL_TABLES", Array) do |tables|
      tables_to_sync = []
      for entry in tables do
      	tables_to_sync << entry
      end
    end

    opts.on("", "--commit", " tell us whether or not to actually run queries -- the default is to not run queries") do
      actually_run_queries = true
    end

    opts.on("-z", "--extra_sql=STRING", "specify an sql sql string to run after the script ends [in the 'to' database]") do |sql|
      my_options[:extra_sql] = sql
    end

    opts.on('-q', '--quiet', 'Non-verbose -- dont output as much junk, just the summaries') do |quiet_true|
    verbose = false
    end
    
    opts.on('--perform_structure_sync_only', "Do a structure morph for the designated tables -- Use it with --tables=STRUCTURE_SYNC_THE_WHOLE_THING to drop any existing tables not found in the origin database and structure sync over any existing tables -- see the docs http://code.google.com/p/ruby-roger-useful-functions/wiki/TableSyncer") do
      do_structure_sync_only = true
    end


    opts.on('-i', '--inserts_only', 'do_inserts_only') do
    	my_options[:do_inserts_only] = true
    end

  end.parse!

  # grab the right db's
  db_from_info = db_to_info = nil
  print "from db: #{db_from_name}\n"
  eval("db_from_info = #{db_from_name}")
  print "to db: #{db_to_name}\n"
  eval("db_to_info = #{db_to_name}")
  raise 'missing a database selected?' unless db_to_info and db_from_info

  # skip the necessity for -y if a db is set to :expendable
  my_options[:skip_the_warning_prompt_for_commit] = true if db_to_info[:expendable]

  # raise if they attempt to commit to a db which has :read_only => true set in its options
  raise 'attempting to commit to a read only db ' + db_to_name if db_to_info[:read_only] and actually_run_queries

  # custom parse table names they have within the parameters
  unless tables_to_sync
	extra_table_args = ARGV.select{|arg| arg[0..0] != '-'}
    if extra_table_args.length > 0
      tables_to_sync = []		
      for arg in extra_table_args
        tables_to_sync  += Array(arg.split(','))
      end	
    elsif default_tables_to_sync
      tables_to_sync = default_tables_to_sync	
    else
      print 'no tables specified! run with --help', "\n"
      exit
    end
  else
    if ARGV.find{|arg| arg[0..0] != '-'}
      print "warning--ignoring some apparently extra parameters at the end, since you passed in tables via a command line arg"
    end
  end
ARGV.clear
raise 'must specify tables or ALL for structure_sync to work--we\'re conservative and disallow it otherwise' if tables_to_sync.empty? and do_structure_sync_only

example_out_file = File.open 'would_have_run.sql' , 'w' unless actually_run_queries


class Hash
	def to_sql_update_query(table_name, nonmatching_keys) # ltodo take some 'params' :)
		raise unless self['id']
		query = "update #{table_name} set"
 		comma = ''
		self.each_key do |key|
      # Add gsub("\\","\\\\\\\\") to fix the issue of '\' deleted
			query << "#{comma} #{key} = #{self[key] ? "'" + self[key].gsub("\\","\\\\\\\\").gsub("'", "\\\\'") + "'": 'NULL'}" if nonmatching_keys.include? key
			comma = ',' if nonmatching_keys.include? key
		end
		query << " where id = #{self['id']}"
	end

	def to_sql_create_query(table_name)
		query = "insert into #{table_name} ("
		comma = ''
		self.each_key { |key_name|
			query += "#{comma}#{key_name} "
			comma = ','
		}
		query += ") values ( "
		comma = ''
		self.each_key { |key_name|
      # Add gsub("\\","\\\\\\\\") to fix the issue of '\' deleted
			query += "#{comma} #{self[key_name] ? "'" + self[key_name].gsub("\\", "\\\\\\\\").gsub("\"","").gsub("'", "\\\\'") + "'" : 'NULL'}" # assume it will leave the others are null, I guess
			comma = ','
		}
	 	query += ");"
	end		
end

  def sync_structure(db_to, db_from, table, actually_run_queries, my_options)
  print "structure syncing #{table}\n"
  good_structure = db_from.query("desc #{table}")
  all_from_columns = {}
  good_structure.each_hash{|h| all_from_columns[h['Field']] = h }
  good_structure.free
  # we basically cheat and just fakely recreate mismatched columns by "modifying them" to match the creation script given by 'show create table x' for that column
  good_creation_query = db_from.query("show create table #{table}")
  create_whole_table_script = good_creation_query.fetch_hash['Create Table']
  good_creation_script = create_whole_table_script.split("\n")
  good_creation_query.free

  questionable_to_structure = db_to.query("desc #{table}") rescue nil
  unless questionable_to_structure 
      if actually_run_queries
	db_to.query(create_whole_table_script)
      else
	print "would have created new table #{table} thus: #{create_whole_table_script}\n"
	db_to = db_from # fake it that they match so we don't raise any errors for the duration of this method call
      end
      questionable_to_structure = db_to.query("desc #{table}")
  end

  all_to_columns = {}
  questionable_to_structure.each_hash{|h| all_to_columns[h['Field']] = h }
  questionable_to_structure.free

  for column_name, specs in all_from_columns do

  	matching_creation_line = good_creation_script.find{|line| line =~ /^\s*`#{column_name}`/} # starts with column name--kind of fallible, but hey, we're working with english single words here

  	matching_to_column_specs = all_to_columns[column_name]
  	matching_creation_line = matching_creation_line[0..-2] if matching_creation_line[-1..-1] == ','
  	unless matching_to_column_specs # get it from the script
  		# create it
  		if specs['Extra'] != ''
  			raise "uh oh currently we don't sync id's they're assumed to exist already! Try deleting the old column #{column_name} or table #{table} entirely"
  		end

  		running = "ALTER TABLE #{table} ADD COLUMN #{matching_creation_line}"
  		print "running #{running}-- for #{column_name}\n"
  		db_to.query running if actually_run_queries
          else
  		# we don't want key differences to make a difference--those are handle after
  		to_specs_non_keyed = matching_to_column_specs.dup
                  specs_non_keyed = specs.dup
  		to_specs_non_keyed.delete('Key')
  		specs_non_keyed.delete('Key')
  		if specs_non_keyed != to_specs_non_keyed
  			line = "ALTER TABLE #{table} CHANGE #{column_name} #{matching_creation_line}"

			# for some reason the create table script doesn't include defaults if they're NULL or ''
			unless line =~ /default/i
				if specs_non_keyed['Default'] == nil
				   line += " DEFAULT NULL"
				else
				   line += " DEFAULT '#{ specs_non_keyed['Default'] }'"
			 	end
			end
  			print "modifying #{column_name} -- #{line} \n"
			print "#{specs_non_keyed.inspect} != the to guy: #{to_specs_non_keyed.inspect}"
  			db_to.query line if actually_run_queries
  	  end	
  		all_to_columns.delete(column_name)
  	end
   end

   for column_name, description in all_to_columns # left overs
		print "REMOVING COLUMN #{column_name}"
		db_to.query("ALTER TABLE #{table} DROP #{column_name}") if actually_run_queries
   end

   indices = db_from.query("show index from #{table};")
   all_indices = []
   indices.each_hash{|h| h.delete('Cardinality'); all_indices << h } # Cardinality doesn't make a difference...AFAIK
   indices.free

   existing_indices = db_to.query("show index from #{table}")
   all_existing_indices = []
   existing_indices.each_hash{|h| h.delete('Cardinality'); all_existing_indices << h }
   existing_indices.free
   different = []
   all_different = all_indices - all_existing_indices #.each{|hash| different << hash['Column_name'] unless existing_indices.include?(hash) }
   apparently_lacking = all_indices.map{|index| index['Column_name']} - all_existing_indices.map{|index| index['Column_name']}

   

   for index in apparently_lacking
	    # ltodo if it looks nice and generic then go ahead and add it
   end



   if all_indices != all_existing_indices # this is right
     print "\n\nWARNING #{table}: you are missing some indexes now or there is some type of discrepancy [indices aren't handled yet]-- you may want to add them a la\nCREATE INDEX some_name_usually_column_name_here ON #{table} (column_name_here)\n for apparently at least the following missing indices: #{apparently_lacking.inspect} 

            you have apparently mismatched indices for: #{all_different.map{|h| h['Column_name']}.inspect}\n\n
             --you might get away with dropping the old table and letting it be recreated -- that might add the right indices -- run with --verbose to see more info"

     if my_options[:verbose]
	print "the 'good' one is #{all_indices.inspect}, yours is #{all_existing_indices.inspect}"
     end
   end 
end

   if db_from_info[:ssh_host]
		db_from_info[:host] = db_from_info[:ssh_local_to_host] || '127.0.0.1'
		db_from_info[:port] = 4000
   end

   if db_to_info[:ssh_host]
		db_to_info[:host] = db_from_info[:ssh_local_to_host] || '127.0.0.1'
		db_to_info[:port] = 4000
   end
   commit_style = actually_run_queries ? '---COMMITTING----' : 'previewing (no changes made)'

   print "#{db_from_info[:db]} => #{db_to_info[:db]}\n\n"
   print "#{commit_style} run\n\n"
   print "#{db_from_info[:ssh_host] || db_from_info[:host]}:#{db_from_info[:db]} #{tables_to_sync.inspect}\n"
   print "\t=> #{db_to_info[:ssh_host] || db_to_info[:host]}:#{db_to_info[:db]} #{tables_to_sync.inspect}\n"
   # ltodo add in the local_to_stuff here
   
   if actually_run_queries and !my_options[:skip_the_warning_prompt_for_commit] 
	print "Continue (y/n)?"
	input = gets
	if !['y', 'yes'].include? input.downcase.strip
		print "aborting -- you gave me #{input}"
		exit
	end
   end
   
   
   start_time = Time.now 
   retried = false
   begin
     # connect to the MySQL servers
     print 'connecting to to DB...', db_to_info[:db]; STDOUT.flush
     db_to = Mysql.real_connect(db_to_info[:host], db_to_info[:user], db_to_info[:password], db_to_info[:db], db_to_info[:port], nil, Mysql::CLIENT_COMPRESS)
     print 'connected', "\n", 'now connecting to from DB ', db_from_info[:db]; STDOUT.flush
     db_from = Mysql.real_connect(db_from_info[:host], db_from_info[:user], db_from_info[:password], db_from_info[:db], db_from_info[:port], nil, Mysql::CLIENT_COMPRESS)
     print "connected\n"
   rescue Mysql::Error => e
     puts "Error code: #{e.errno}"
     puts "Error message: #{e.error}"
     puts "This may mean a tunnel is not working" if e.error.include?('127.0.0.1')
     # note that, if you do add ssh -> ssh, you may still only need one connection!
     if db_from_info[:ssh_host] or db_to_info[:ssh_host]
       
        if (db_from_info[:ssh_host] and db_to_info[:ssh_host]) and (db_from_info[:ssh_host] !=- db_to_info[:ssh_host])
	   if(!db_from_info[:tunnel_local_port_to_use] or !db_to_info[:tunnel_local_port_to_use])
	      raise "if you want to connect to two different remote dbs via ssh, you'll need to assign them each a port so they're distinct" # todo: always require different ports
	   end
	end

        ssh_requiring_connection = db_to_info[:ssh_host] ? db_to_info : db_from_info
	ssh_port = ssh_requiring_connection[:ssh_port]
	ssh_local_to_port = ssh_requiring_connection[:ssh_local_to_port] || 3306
	ssh_user = ssh_requiring_connection[:ssh_user]
	ssh_local_to_host = ssh_requiring_connection[:ssh_local_to_host] || 'localhost'
	ssh_host = ssh_requiring_connection[:ssh_host]

        local_port_to_use = ssh_requiring_connection[:tunnel_local_port_to_use] || 4000
        
	command = "ssh -N #{ssh_port ? '-p ' + ssh_port.to_s : nil} -L #{local_port_to_use}:#{ssh_local_to_host}:#{ssh_local_to_port} #{ssh_user}@#{ssh_host} \n" # note that ssh_local_to_port is 'local on the foreign server'
        if auto_create_ssh_tunnels and !retried
            print "trying  to auto create ssh tunnel via: #{command}\n"
	    Thread.new { system(command) }
	    retried = true # this doesn't actually work :P
	    retry
        else
	  print "unable to connect to server--try running\n\t#{command}in another window or try again!\n"
        end
     end
     exit
   ensure
     # ltodo: disconnect from server here [?] -- also do we free, and disconnect, at all, during this? :)
   end

  summary_information = '' # so we can print it all (again), at the end

  # we need to delete any extra tables if they're there in one and not the other
  if do_structure_sync_only and tables_to_sync == ['STRUCTURE_SYNC_THE_WHOLE_THING'] or tables_to_sync == ['ALL_TABLES']
    tables_from = db_from.query("show tables")
    tables_from_array = []
    tables_from.each_hash {|h| h.each{|k, v| tables_from_array << v}}
    tables_from.free
    tables_to_sync = tables_from_array
    if tables_to_sync == ['STRUCTURE_SYNC_THE_WHOLE_THING'] # then we want to drop some tables if they exist
      tables_to = db_to.query("show tables")
      tables_to_array = []
      tables_to.each_hash {|h| h.each{|k, v| tables_to_array << v}}
      tables_to.free
      nukables = tables_to_array - tables_from_array
      for table in nukables do
        query = "DROP TABLE #{table}"
        print "dropping table -- #{query}\n"
        db_to.query(query) if actually_run_queries
      end
    end
  end

  for table in tables_to_sync  do
   print "start #{commit_style} table #{table}" + "**" * 10 + "\n"
   if do_structure_sync_only
     sync_structure(db_to, db_from, table, actually_run_queries, my_options)
     next
   end
  
   all_to_keys_not_yet_processed = {}
   select_all_to = db_to.query("SELECT * FROM #{table}") # could easily be 'select id', as well note this assumes distinct id's! Otherwise we'd need hashes, one at a time, etc. etc.
   select_all_to = select_all_to
   select_all_to.each_hash { |to_element|
	if all_to_keys_not_yet_processed[to_element['id']] # duplicated id's are a fringe case and not yet handled! TODO use hashes or somefin' bet-uh
		raise "\n\n\n\nERROR detected a duplicated id (or the lack of id at all) in #{table} -- aborting [consider clearing [DELETE FROM #{table} in the 'to' database and trying again, if in a pinch]!\n\n\n\n" 
	end
	all_to_keys_not_yet_processed[to_element['id']] = to_element
   }

   res = db_from.query("SELECT * from #{table}")
   res = res
   count_updated = 0
   count_created = 0
   
   res.each_hash do |from_element|
	existing = all_to_keys_not_yet_processed[from_element['id']]
	# now there are a few cases--we can find a matching id->rest locally, or an id->nonmatching (update) or non_id (insert)
	# the problem is that we need to keep track of which id's we never used, and delete them from the offending table, afterward
	if existing # we have a match--test if it is truly matching
		to_element = existing# ltodo rename
		all_nonmatching_keys = []
		for key in from_element.keys do
			if from_element[key] != to_element[key]
				all_nonmatching_keys << key
				print  " #{key}\t\t\t[", from_element[key].inspect, "]!!!!======to:[", to_element[key].inspect||'',  ']', "\n" if verbose
			else
				# equal, ok
			end

		end
		if all_nonmatching_keys.length > 0
			count_updated += 1
			query = from_element.to_sql_update_query(table, all_nonmatching_keys)
			print "update query on #{to_element['name']}: #{query}\n" if verbose
			db_to.query query if actually_run_queries
			example_out_file.write query + ";\n" unless actually_run_queries
		end
	else
		count_created += 1
		create_query = from_element.to_sql_create_query(table)
		print "insert query on #{from_element['name']}: #{create_query}\n" if verbose
		db_to.query create_query if actually_run_queries
		example_out_file.write create_query + ";\n" unless actually_run_queries
        end
	all_to_keys_not_yet_processed.delete(from_element['id'])
   end
   print "\n" if (count_updated>0 or count_created>0) if verbose


   if(my_options[:do_inserts_only])
     print "skipping deletions, as you passed in do_inserts_only\n"
   else
    count_deleted = all_to_keys_not_yet_processed.length
    if count_deleted > 0
     ids = []
     for id in all_to_keys_not_yet_processed.keys do
       ids << id 
     end
     double_check_all_query = "select * from #{table} where id IN (#{ids.join(',')})" # this allows us to make sure we don't delete any doubled ones (which would be a weird situation and too odd to handle), and also so we can have a nice verbose  'we are deleting this row' message
     double_check_result = db_to.query(double_check_all_query)
     double_check_result = double_check_result


     victims = {}

     double_check_result.each_hash {|victim|
        raise 'duplicate' if victims[victim['id']]
        victims[victim['id']] = victim['name']
     }
     raise 'weird deleted--got back strange number of rows -- refusing to delete' unless double_check_result.num_rows == count_deleted
     double_check_result.free
     for id in all_to_keys_not_yet_processed.keys do
       query = "delete from #{table} where id = #{id}"
       print "DELETE query, for #{victims[id]} is #{query}\n" if verbose
       db_to.query query if actually_run_queries
       example_out_file.write query + ";\n" unless actually_run_queries
     end
    end
   end

   res.free
   print "done #{commit_style} "
   summary =  "#{table} -- updated #{count_updated}, created #{count_created}, deleted #{count_deleted}\n"
   print summary
   summary_information << summary
  end
  if my_options[:extra_sql] and actually_run_queries
    print "doing sql #{my_options[:extra_sql]}\n"
    result = db_to.query( my_options[:extra_sql])
    # result will only be a result set if it was a select query
    
    if result
      require 'pp'
      while row = result.fetch_row do
        pp row
      end
      result.free
    end
  end
  db_from.close if db_from
  db_to.close if db_to
  print "\n--summary--\n", summary_information
  print "total transfer time #{Time.now - start_time}\n"

# Todo list:
# inlined todo notes
# ltodo: some SSH examples in here
# ltodo: optionally 'only add from one to the other' -- only add new entries past the current maxes for the table
# ltodo: one BIG transaction, so that ctrl+c will work. [?]
# ltodo: read_only directive
# todo by default output a 'backup' log somewhere, too! oh baby! 10 of them! what the heck! :)
# just needs docs and rock and roll [publicize] :)
# note this lacks 'transaction's thus far
# and its SSH is hackish, requiring the user to start a tunnel in another window
# ltodo: tell people how to install ssh for windows users [?]
# TODO sql escape things better (does it a little already) [use mysql escape function itself or whatever it is]
# TODO could use a 'mass insert' and mass delete to speed things up (several giant strings batch mode) 
# could do: something along the lines of rsync for database tables--calculate some checksums, foreign host, etc., anything to save on bandwidth lol. It is, however, true that most changes come from the "latter end" of tables so...probably has tons of potential savings
# ltodo handle ssh => ssh [separate hosts] -- note: may want to specify a 'local port' per ssh host :)
# could do: download from both people at the same time, per table, or what not muhaha
# could do: some more free's in here [double check to make sure I free everwhere]
# TODO when it does something require keyboard input unless they specify --force or something
# ltodo handle ginormous tables :) that wouldn't ever ever fit in memory :)
# could do: have this cool 'difference since then' setting thingers...like...ok you sync'ed that since then, you've changed this much we know, and that one has changed that much, we know...so the sum diff is...
# whoa!
# ltodo: you can chain together a few updates, too, a la "update x where y; update z where q; update a where b;" or the 'super table mass updater' that uses a temp table lol
# :)
# need to use my_options for the syncing stuff, clean up code, too
# todo: this errs
#>> gc.description.pretty_inspect=> ""GCU\\\\â€™s Bachelor of Science in Entrepreneurial Studies program is built on the principles of personal integrity, values, and innovation. Emphasizing the philosophy of being an \\"Entrepreneurial School by Entrepreneurs,\\" the program provides students with the skills to think analytically, ask the right questions, solve problems, and function as an entrepreneur in both small and large companies. Students are prepared to be self-motivated, self-managed, and self-disciplined entrepreneurs with the skill-set to manage their own careers either by starting their own business venture or working within a start-up, entrepreneurial business environment. Interaction with successful entrepreneurs, business consulting opportunities, and individual venture capital projects are highlighted in the program."\n"
#>> gc.description
#=> "GCU\\â€™s Bachelor of Science in Entrepreneurial Studies program is built on the principles of personal integrity, values, and innovation. Emphasizing the philosophy of being an "Entrepreneurial School by Entrepreneurs," the program provides students with the skills to think analytically, ask the right questions, solve problems, and function as an entrepreneur in both small and large companies. Students are prepared to be self-motivated, self-managed, and self-disciplined entrepreneurs with the skill-set to manage their own careers either by starting their own business venture or working within a start-up, entrepreneurial business environment. Interaction with successful entrepreneurs, business consulting opportunities, and individual venture capital projects are highlighted in the program."




=begin
multiple insertions ex:
   dbh.query("INSERT INTO animal (name, category)
                VALUES
                  ('snake', 'reptile'),
                  ('frog', 'amphibian'),
                  ('tuna', 'fish'),
                  ('racoon', 'mammal')
              ")

class MultipleDeleter # not thread safe
  @@batch_max = 1000;
  def initialize connection, table_name
   @connection = connection
   @table_name = table_name
   ids = []
  end

  def add_id_t_delete id
   ids << id
   if ids.length == @@batch_max
     send
   end
  end

  def send
     @connection.query "delete from #{@table_name} where id IN (#{ids.join(',')});"
     ids = []
  end

  def flush
    send
  end
end
=end


# ltodo: alias for table names :) czs, ps, etc :)

# we really need to be able to handle many to many: just use a hash + counter based system instead of an id based system
# ltodo: use mysql table checksum :)
# ltodo: lacks using port besides 3306 locally
