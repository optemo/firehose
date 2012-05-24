# CHANGE THIS TO 2 WHEN FUTURESHOP ALSO GIVES EMAILS 
NUMBER_OF_RETAILERS = 2

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
    
    # May need to login to both e-mail addresses
    # This will work even after Best Buy starts sending both e-mails to auto@optemo.com, though it will unecessarily access files@optemo.com
    
    addresses = 0
    if spec == "pageviews"
      addresses = 2
    else
      addresses = 1
    end
    
    while addresses > 0
      imap = Net::IMAP.new('imap.1and1.com')
      if addresses == 2
        imap.login('files@optemo.com', '***REMOVED***')
      else
        imap.login('auto@optemo.com', '***REMOVED***')
      end
      addresses -= 1
      search_for = ""
      if spec == "pageviews"
        search_for_bb = "/x5lp"
        search_for_fs = "/1js8v"
      else
        search_for_bb = "/rzf4"
        search_for_fs = "/1js8w"
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
    
      # Read each message 
      msgs.reverse.each do |msgID| 
        msg = imap.fetch(msgID, ["ENVELOPE","UID","BODY"] )[0]
    
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
            p then_date
            cName = ""
            fs_type = ""
            unless type_csv
              cName = "#{Rails.root}/tmp/#{then_date}.zip"
            else
              if search_for_fs == "/1js8v"
                fs_type = "FutureShopPageviews - #{then_date.strftime("%a. %d %m %Y")}.csv"
              else
                fs_type = "FutureShopOrders - #{then_date.strftime("%a. %d %m %Y")}.csv"
              end
              cName = "#{Rails.root}/tmp/#{fs_type}"
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
              csvfile = File.join("#{Rails.root}/tmp/", fs_type)
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
    end
  rescue Exception => e
    puts e.message
    raise e
  end
end