# CHANGE THIS TO 2 WHEN FUTURESHOP ALSO GIVES EMAILS 
NUMBER_OF_RETAILERS = 2

FUTURE_SHOP_PAGEVIEWS_KEY = "/1js8v"
FUTURE_SHOP_ORDERS_KEY = "/1js8w"
BEST_BUY_PAGEVIEWS_KEY = "/1ko3s"
BEST_BUY_ORDERS_KEY = "/1ko3r"

# Set extra data options given the spec and table names
def set_needed_fields (spec_name, table_name)
  if spec_name =~ /[Pp]ageviews?/
    task_data = {:first_possible_date => "29-Oct-2011", :spec => "pageviews", :table => table_name}
  elsif spec_name =~ /([Oo]nline)?[\s_]?[Oo]rders/
    task_data = {:first_possible_date => "09-Sep-2011", :spec => "online_orders", :table => table_name}
  else
    p "Invalid spec_name. Please try again."
  end
  p "Task data block run"
  return task_data
end

# Opens the attachments for the days specified, processes and saves their data to the table specified
def save_email_data (task_data,daily_updates,start_date,end_date)
  begin
    require 'net/imap'
    require 'zip/zip'
    require 'orders_pageviews_saving'
    spec = task_data[:spec]
    retailers_received = []
    
      imap = Net::IMAP.new('imap.1and1.com')
      
      imap.login('auto@optemo.com', '***REMOVED***')
      search_for = ""
      if spec == "pageviews"
        search_for_bb = BEST_BUY_PAGEVIEWS_KEY
        search_for_fs = FUTURE_SHOP_PAGEVIEWS_KEY
      else
        search_for_bb = BEST_BUY_ORDERS_KEY
        search_for_fs = FUTURE_SHOP_ORDERS_KEY
      end
      
      imap.select('INBOX') 
    
      # Get the messages wanted
      if (start_date || end_date) && !daily_updates # If a date is given or it is not running the production update...
        only_last = false  
        if start_date 
          since = start_date.next_day.strftime("%d-%b-%Y")
          if end_date # If end date given, read emails in range
            before = (end_date+2).strftime("%d-%b-%Y")

            msgs = imap.search(["SINCE", since, "BEFORE", before, "OR", "BODY", search_for_fs, "BODY", search_for_bb])

          else # If no end date specified, go to last email received ('today')
            msgs = imap.search(["SINCE", since, "BEFORE", Date.today.strftime("%d-%b-%Y"), "OR", "BODY", search_for_fs, "BODY", search_for_bb])
          end
        elsif end_date # If no start date given, but end date is, go from first email to end_date
          before = (end_date+2).strftime("%d-%b-%Y") 
          
          msgs = imap.search(["SINCE", "#{task_data[:first_possible_date]}","BEFORE", before, "OR", "BODY", search_for_fs, "BODY", search_for_bb])
        end
      else
        only_last = true  #only process the last email
      
        msgs = imap.search(["SINCE", "#{task_data[:first_possible_date]}", "OR", "BODY", search_for_fs, "BODY", search_for_bb])
      end

      if msgs.length == 0
        puts "\nERROR: No e-mails found. Check the webmail inbox and see if the following key-phrases in the message bodies have changed:"
        puts "Future Shop Pageviews: https://www2.omniture.com/x#{FUTURE_SHOP_PAGEVIEWS_KEY}"
        puts "Future Shop Orders: https://www2.omniture.com/x#{FUTURE_SHOP_ORDERS_KEY}"
        puts "Best Buy Pageviews: https://www2.omniture.com/x#{BEST_BUY_PAGEVIEWS_KEY}"
        puts "Best Buy Orders: https://www2.omniture.com/x#{BEST_BUY_ORDERS_KEY}"
        puts "If these do not match the webmail messages, update the variables in firehose/lib/email_data_collection.rb\n\n"
      end
      
      # Read each message 
      msgs.reverse.each do |msgID| 
        msg = imap.fetch(msgID, ["ENVELOPE","UID","BODY", "BODY[TEXT]"] )[0]
        
      # Only those with 'SOMETEXT' in subject are of our interest 
        if msg.attr["ENVELOPE"].from[0].host == "omniture.com"
          body = msg.attr["BODY"] 
          i = 1
          while body.parts[i] != nil 
        
      # Additional attachments attributes 
            i+=1
            next if body.parts[i-1].param.nil? || body.parts[i-1].media_type.nil?
            next unless body.parts[i-1].media_type == "APPLICATION" || body.parts[i-1].media_type == "TEXT"
            type_csv = false
            type_csv = true if body.parts[i-1].media_type == "TEXT"
            csvfile = ""
            then_date = Date.parse(msg.attr["ENVELOPE"].date)-1
            cName = ""
            type = ""
            unless type_csv
              cName = "#{Rails.root}/tmp/#{then_date}.zip"
            else
              text = msg.attr["BODY[TEXT]"]
              if text.include?(FUTURE_SHOP_PAGEVIEWS_KEY)
                type = "FutureShop Pageviews - #{then_date.strftime("%a. %d %m %Y")}.csv"
              elsif text.include?(FUTURE_SHOP_ORDERS_KEY)
                type = "FutureShop Orders - #{then_date.strftime("%a. %d %m %Y")}.csv"
              elsif text.include?(BEST_BUY_PAGEVIEWS_KEY)
                type = "BestBuy Pageviews - #{then_date.strftime("%a. %d %m %Y")}.csv"
              elsif text.include?(BEST_BUY_ORDERS_KEY)
                type = "BestBuy Orders - #{then_date.strftime("%a. %d %m %Y")}.csv"
              end
              cName = "#{Rails.root}/tmp/#{type}"
              tmpfile = File.new(cName, 'w')
              tmpfile.close
            end
      # Fetch attachment. 
            attachment = imap.fetch(msgID, "BODY[#{i}]")[0].attr["BODY[#{i}]"] 
      
      # Save message, BASE64 decoded 
            File.open(cName,'wb+') do |f|
              f.write(attachment.unpack('m')[0])
            end
          
            unless type_csv
            # Unzip file
              #I coulnd't figure out how to unzip a string, otherwise we could do this whole thing in memory instead of temp files
              Zip::ZipFile.open(cName) do |zip_file|
                 zip_file.each do |f|
                   f_path=File.join("#{Rails.root}/tmp/", f.name)
                   csvfile = f_path
                   FileUtils.mkdir_p(File.dirname(f_path))
                   zip_file.extract(f, f_path) unless File.exist?(f_path)
                 end
              end
            else
              csvfile = File.join("#{Rails.root}/tmp/", type)
            end

      # Open csv file, process data, save sales or pageviews
            contspecs = []
            #sometimes the top email will be a weekly email.  I don't want to process this
            weekly=false
            if csvfile =~ /.+-.+-.+/
              weekly=true
            end
          
            unless csvfile.blank? || weekly
              before_whole = Time.now()

              # This should work both for the old and new product_types (camera_bestbuy vs. B20218)
              # neither drives nor camera has an 'f'
              /(?<retailer>[Bb])est[Bb]uy|(?<retailer>[Ff])uture[Ss]hop/ =~ File.basename(csvfile)
              if !retailers_received.include?(retailer) || !only_last
                retailers_received.push(retailer)
                data_date = then_date.strftime("%Y-%m-%d")
                if spec == "pageviews"
                  save_pageviews(csvfile,data_date,daily_updates,task_data[:table],retailer)
                elsif spec == "online_orders"
                  save_online_orders(csvfile,data_date,daily_updates,task_data[:table],retailer)
                end
                after_whole = Time.now()
              end
            end
        
            # Delete files used
            unless type_csv
              File.delete(cName,csvfile)
            else
              File.delete(csvfile)
            end
          end 

          if only_last && retailers_received.uniq.length == NUMBER_OF_RETAILERS
            break; #Only process the first email, unless that email is a weekly email
          end
        end 
      end
      imap.close
      imap.disconnect
  rescue Exception => e
    puts e.message
    raise e
  end
end