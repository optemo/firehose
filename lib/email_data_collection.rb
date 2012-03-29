# CHANGE THIS TO 2 WHEN FUTURESHOP ALSO GIVES EMAILS 
NUMBER_OF_RETAILERS = 1

# Set extra data options given the spec and table names
def set_needed_fields (spec_name, table_name)
  if spec_name =~ /[Pp]ageviews?/
    task_data = {:first_possible_date => "29-Oct-2011", :spec => "pageviews", :table => table_name}
  elsif spec_name =~ /([Oo]nline)?[\s_]?[Oo]rders/
    task_data = {:first_possible_date => "09-Sep-2011", :spec => "online_orders", :table => table_name}
  else
    p "Invalid spec_name. Please try again."
  end
  return task_data
end

# Opens the attachments for the days specified, processes and saves their data to the table specified
def save_email_data (task_data,daily_updates,start_date,end_date)
  require 'net/imap'
  require 'zip/zip'
  require 'orders_pageviews_saving'
  spec = task_data[:spec]
  retailers_received = []

  imap = Net::IMAP.new('imap.1and1.com') 
  if spec == "pageviews"
    imap.login('files@optemo.com', '***REMOVED***') 
  else # ... if online_orders
    imap.login('auto@optemo.com', '***REMOVED***')
  end
  imap.select('INBOX') 
  
  # Get the messages wanted
  if (start_date || end_date) && !daily_updates # If a date is given or it is not running the production update...
    only_last = false  
    if start_date 
      since = start_date.next_day.strftime("%d-%b-%Y")
      if end_date # If end date given, read emails in range
        before = (end_date+2).strftime("%d-%b-%Y")
        msgs = imap.search(["SINCE", since,"BEFORE", before])
      else # If no end date specified, go to last email received ('today')
        msgs = imap.search(["SINCE", since,"BEFORE", Date.today.strftime("%d-%b-%Y")])
      end
    elsif end_date # If no start date given, but end date is, go from first email to end_date
      before = (end_date+2).strftime("%d-%b-%Y") 
      msgs = imap.search(["SINCE", "#{task_data[:first_possible_date]}","BEFORE", before])
    end
  else
    only_last = true  #only process the last email
    msgs = imap.search(["SINCE", "#{task_data[:first_possible_date]}"])
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
        next unless body.parts[i-1].media_type == "APPLICATION"
        then_date = Date.parse(msg.attr["ENVELOPE"].date)
        Dir.mkdir("#{Rails.root}/tmp/#{task_data[:spec]} zip") unless File.exists?("#{Rails.root}/tmp/#{task_data[:spec]} zip")
        cName = "#{Rails.root}/tmp/#{task_data[:spec]} zip/#{then_date}.zip" 
  # Fetch attachment. 
        attachment = imap.fetch(msgID, "BODY[#{i}]")[0].attr["BODY[#{i}]"] 
        
  # Save message, BASE64 decoded 
        File.open(cName,'wb+') do |f|
          f.write(attachment.unpack('m')[0])
        end
        
  # Unzip file
        #I coulnd't figure out how to unzip a string, otherwise we could do this whole thing in memory instead of temp files
        csvfile = ""
        Zip::ZipFile.open(cName) do |zip_file|
           zip_file.each do |f|
             f_path=File.join("#{Rails.root}/tmp/#{task_data[:spec]}/", f.name)
             csvfile = f_path
             FileUtils.mkdir_p(File.dirname(f_path))
             zip_file.extract(f, f_path) unless File.exist?(f_path)
           end
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
          /(?<retailer>[Bb])est[Bb]uy|(?<retailer>[Ff])uture[Ss]hop/ =~ File.basename(csvfile)
          if !retailers_received.include?(retailer) || !only_last
            retailers_received.push(retailer)
            data_date = then_date.prev_day().strftime("%Y-%m-%d")
            if spec == "pageviews"
              save_pageviews(csvfile,data_date,daily_updates,task_data[:table],retailer)
            else
              save_online_orders(csvfile,data_date,daily_updates,task_data[:table],retailer)
            end
            
            after_whole = Time.now()
            p "Time for sales of #{data_date}: #{after_whole-before_whole}"
          end
        end
      end 

      if only_last && retailers_received.uniq.length == NUMBER_OF_RETAILERS
        break; #Only process the first email, unless that email is a weekly email
      end
    end 
  end 
  imap.close
end