def save_daily_sales (table)
  require 'net/imap'
  require 'zip/zip'
  imap = Net::IMAP.new('imap.1and1.com') 
  imap.login('auto@optemo.com', '***REMOVED***') 
  imap.select('Inbox') 
  
  # Reset this to true afterwards
  
  only_last=false    #only process the last email
  # All msgs in a folder 
  msgs = imap.search(["SINCE", "01-Mar-2012","BEFORE", "02-Mar-2012"])
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
        
        orders_map = {} # map of sku => orders
        
        unless csvfile.blank? || weekly
          
          #### THIS DOES THE PROCESSING OF THE CSV FILE
          orders_map = {} # map of sku => orders
          
          File.open(csvfile, 'r') do |f|
            f.each do |line|
              /\d+\.,,(?<sku>[^,]+),,(?<rev>"?\$\d+(,\d+)?"?),,,,[^,]+,,(?<orders>\d+)/ =~ line
              orders_map[sku] = orders if sku
            end
          end
          case table
          when "daily_specs"
            # Only select the products that have some existing spec in the daily spec table for that day
            # For addition to DailySpec  
            date = then_date.prev_day().strftime("%Y-%m-%d")
            products = DailySpec.where(:date => date).select("DISTINCT(sku)")
            products.each do |prod|
              sku = prod.sku
              product_type = DailySpec.find_by_sku_and_value_txt(sku, nil).product_type
              orders_spec = orders_map[sku].try(:delete,',') # For sales of over 999 (comma messes things up)
              orders = (orders_spec.nil?) ? "0" : orders_spec
              # write orders to daily_sales for the date and the sku
              ds = DailySpec.find_or_initialize_by_spec_type_and_sku_and_name_and_value_flt_and_date_and_product_type("cont",sku,'orders',orders,date,product_type)
              ds.save if ds.new_record?
            end
          when "all_daily_specs"
            # For addition to AllDailySpec
            date = then_date.prev_day().strftime("%Y-%m-%d")
            products = AllDailySpec.where(:date => date).select("DISTINCT(sku)")
            products.each do |prod|
              sku = prod.sku
              product_type = AllDailySpec.find_by_sku_and_date(sku, date).product_type
              orders_spec = orders_map[sku].try(:delete,',') # Not so much an issue here
              orders = (orders_spec.nil?) ? "0" : orders_spec
              # write orders to daily_sales for the date and the sku
              debugger # have not yet been able to test this
              ds = DailySpec.find_or_initialize_by_spec_type_and_sku_and_name_and_value_flt_and_date_and_product_type("cont",sku,'online_orders',orders,date,product_type)
              ds.save if ds.new_record?
            end
          end
        end
  # ******************************************
      end 
      if only_last
        break; #Only process the first email, unless that email is a weekly email
      end
    end 
  end 
  imap.close
end