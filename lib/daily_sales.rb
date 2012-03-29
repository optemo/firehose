def save_daily_sales (table,start_date,end_date)
  require 'net/imap'
  require 'zip/zip'
  #require 'date'
  imap = Net::IMAP.new('imap.1and1.com') 
  imap.login('auto@optemo.com', '***REMOVED***') 
  imap.select('Inbox') 
  # Get the messages wanted
  if start_date || end_date # If a date is given...
    only_last=false  
    if start_date 
      since = start_date.next_day.strftime("%d-%b-%Y")
      if end_date # If end date given read emails in range
        before = (end_date+2).strftime("%d-%b-%Y")
        msgs = imap.search(["SINCE", since,"BEFORE", before])
      else # If no end date specified, go to last email received (today)
        msgs = imap.search(["SINCE", since,"BEFORE", Date.today.strftime("%d-%b-%Y")])
      end
    elsif end_date # If no start date given, but end date is, go from first email to end_date
      before = (end_date+2).strftime("%d-%b-%Y") 
      msgs = imap.search(["SINCE", "09-Sep-2011","BEFORE", before])
    end
  else
    only_last=true  #only process the last email
    # 09-Sep-2011 is earliest possible date for online sales data (daily)
    msgs = imap.search(["SINCE", "09-Sep-2011"])
  end
#  retailers_received = []

  # Read each message 
  msgs.reverse.each do |msgID| 
    msg = imap.fetch(msgID, ["ENVELOPE","UID","BODY"] )[0]
  # Only those with 'SOMETEXT' in subject are of our interest 
    if msg.attr["ENVELOPE"].from[0].host == "omniture.com"
      body = msg.attr["BODY"] 
      i = 1 
      while body.parts[i] != nil 
  # additional attachments attributes 
        i+=1 
        next if body.parts[i-1].param.nil? || body.parts[i-1].media_type.nil?
        next unless body.parts[i-1].media_type == "APPLICATION"
        then_date = Date.parse(msg.attr["ENVELOPE"].date)
        #then_date = Date.parse(msg.attr["ENVELOPE"].date).strftime("%Y-%m-%d")
        cName = "#{Rails.root}/tmp/#{then_date}.zip" 
        
  # fetch attachment. 
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
             f_path=File.join("#{Rails.root}/tmp/", f.name)
             csvfile = f_path
             FileUtils.mkdir_p(File.dirname(f_path))
             zip_file.extract(f, f_path) unless File.exist?(f_path)
           end
        end
  # Open csv file
  # ************* ROBS CHANGES ************
        contspecs = []
        #sometimes the top email will be a weekly email.  I don't want to process this
        weekly=false
        if csvfile =~ /.+-.+-.+/
          weekly=true
        end
        
        unless csvfile.blank? || weekly
          before_whole = Time.now()
          #### THIS DOES THE PROCESSING OF THE CSV FILE
          orders_map = {} # map of sku => orders
     
      #    p "Reading file #{csvfile}"
          File.open(csvfile, 'r') do |f|
            f.each do |line|
              /\d+\.,,(?<sku>[^,]+),,(?<rev>"?\$\d+(,\d+)?"?),,,,[^,]+,,(?<orders>\d+)/ =~ line
              orders_map[sku] = orders if sku
            end
          end

          # This should work both for the old and new product_types (camera_bestbuy vs. B20218)
          /(?<retailer>[Bb])est[Bb]uy|(?<retailer>[Ff])uture[Ss]hop/ =~ File.basename(csvfile)

#          if !retailers_received.include?(retailer) || !only_last
#            retailers_received.push(retailer)

            case table
            when /^[Dd]aily((Spec)|(_specs))/  # Bulk insert
              # Only select the products that have some existing spec in the daily spec table for that day
              # For addition to DailySpec 
              date = then_date.prev_day().strftime("%Y-%m-%d")
              rows = []
       #       if daily
       #         products = Product.where(:instock => 1, :retailer => retailer)
       #         products.each do |prod|
       #           sku = prod.sku
       #           product_type = CatSpec.where(:product_id => prod.id, :name => 'product_type').first.value
       #           orders = (orders_spec.nil?) ? "0" : orders_map[sku].try(:delete,',')
       #           rows.push(["cont",sku,"online_orders",orders,date,product_type])
       #         end
       #       else
                products = DailySpec.where("date = ? AND product_type REGEXP ?",date,retailer).select("DISTINCT(sku)")
                products.each do |prod|
                  sku = prod.sku         
                  product_type = DailySpec.find_by_sku_and_value_txt(sku, nil).product_type
                  orders_spec = orders_map[sku].try(:delete,',') # For sales of over 999 (comma messes things up)
                  orders = (orders_spec.nil?) ? "0" : orders_spec
                  rows.push(["cont",sku,"online_orders",orders,date,product_type])
                end
        #      end
              columns = %W( spec_type sku name value_flt date product_type )
              DailySpec.import(columns,rows,:on_duplicate_key_update=>[:value_flt]) 
            when /^[Aa]ll((DailySpec)|(_daily_specs))/
              # For addition to AllDailySpec
              date = then_date.prev_day().strftime("%Y-%m-%d")
              products = AllDailySpec.where(:date => date).select("DISTINCT(sku)")
              products.each do |prod|
                sku = prod.sku
                product_type = AllDailySpec.find_by_sku_and_date(sku, date).product_type
                orders_spec = orders_map[sku].try(:delete,',') 
                orders = (orders_spec.nil?) ? "0" : orders_spec
                # write orders to daily_sales for the date and the sku
                AllDailySpec.create(:spec_type => "cont", :sku => sku, :name => "online_orders", :value_flt => orders, :date => date, :product_type => product_type)
              end
            end
            after_whole = Time.now()
            p "Time for sales of #{date}: #{after_whole-before_whole}"
#          end
        end
  # ******************************************
      end 
# uncomment below --------|
#                        v
      if only_last #&& retailers_received.uniq.length == NUMBER_OF_RETAILERS
        break; #Only process the first email, unless that email is a weekly email
      end
    end 
  end 
  imap.close
end