def save_daily_sales
  require 'net/imap'
  require 'zip/zip'
  imap = Net::IMAP.new('imap.1and1.com') 
  imap.login('auto@optemo.com', '***REMOVED***') 
  imap.select('Inbox') 
    
  # All msgs in a folder 
  msgs = imap.search(["SINCE", "9-Sep-2011"]) 
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
        then_date = Date.parse(msg.attr["ENVELOPE"].date).strftime("%Y-%m-%d")
        
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
          
          #./log/Daily_Data may not exist as a directory
          FileUtils.mkdir_p("./log/Daily_Data") unless File.directory?("./log/Daily_Data")
          
          #### THIS DOES THE PROCESSING OF THE CSV FILE
          orders_map = {} # map of sku => orders
                    
          cumullative=File.open("./log/Daily_Data/Cumullative_Data_sales.txt",'a')
          
          File.open(csvfile, 'r') do |f|
            f.each do |line|
              /\d+\.,,(?<sku>[^,]+),,(?<rev>"?\$\d+(,\d+)?"?),,,,[^,]+,,(?<orders>\d+)/ =~ line
              orders_map[sku] = orders if sku
            end
          end
          
          instock = DailySpec.where(:date => then_date).select("DISTINCT(sku)")
          instock.each do |prod_sku|
            sku = prod_sku.sku
            product_type = DailySpec.find_by_sku(sku).product_type
            orders_spec = orders_map[sku]
            orders = (orders_spec.nil?) ? "0" : orders_spec
            # write orders to daily_sales for the date and the sku
            ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "sales", :value_flt => orders, :product_type => product_type, :date => then_date)
            to_write=sku.to_s+" "+orders.to_s + " " + product_type + "\n"
            cumullative.write(then_date+" "+to_write)
            ds.save
          end
          cumullative.close()
        end
  # ******************************************
      end 
      #unless weekly
      #  break; #Only process the first email, unless that email is a weekly email
      #end
    end 
  end 
  imap.close
end