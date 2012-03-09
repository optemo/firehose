# FIXME: this function seems to not be called from anywhere. File should probably be removed.
def read_daily_sales
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
        cName = "#{Rails.root}/tmp/#{Time.now.strftime("%y-%m-%d")}.zip" 
        
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
          
          #./log/Daily_Data may not exist as a directory
          FileUtils.mkdir_p("./log/Daily_Data") unless File.directory?("./log/Daily_Data")
          
          #### THIS DOES THE PROCESSING OF THE CSV FILE
          orders_map = {} # map of sku => orders
          
          then_date = Date.parse(msg.attr["ENVELOPE"].date).strftime("%Y-%m-%d")
          today_data=File.open("./log/Daily_Data/"+then_date+".txt",'w')
          cumullative=File.open("./log/Daily_Data/Cumullative_Data.txt",'a')
          File.open(csvfile, 'r') do |f|
            f.each do |line|
              /\d+\.,,(?<sku>[^,]+),,(?<rev>"?\$\d+(,\d+)?"?),,,,[^,]+,,(?<orders>\d+)/ =~ line
              orders_map[sku] = orders if sku
            end
          end
          
          # Changed: instead of looking at instock, get and look up
          # in the daily_specs table which skus are listed for the given date
          instock = DailySpec.where(:date => then_date).select("DISTINCT(sku)")    
          instock.each do |daily_spec|
            sku = daily_spec.sku
            product = Product.find_by_sku(sku)
            puts ("nil for " + sku) if product.nil?
            sku = product.sku
            orders_spec = orders_map[sku]
            orders = (orders_spec.nil?) ? "0" : orders_spec
            u=product.cont_specs.find_by_name("utility")
            
            s=product.cont_specs
            
              puts ActiveRecord::Base.connection
              product_type = "camera_bestbuy"
              camera_features['saleprice', 'price', 'maxresolution', 'opticalzoom', '']
              
              # FIXME: refactor the code below
              specs.each do |attributes|
                sku = attributes[:sku]
                saleprice = attributes[:saleprice]
                maxresolution = attributes[:maxresolution]
                opticalzoom = attributes[:opticalzoom]
                orders = attributes[:orders]
                brand = attributes[:brand]
                featured = attributes[:featured]
                onsale = attributes[:onsale]

                # continuous features
                ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "saleprice", :value_flt => saleprice, :product_type => product_type, :date => date)
                ds.save
                ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "maxresolution", :value_flt => maxresolution, :product_type => product_type, :date => date)
                ds.save
                ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "opticalzoom", :value_flt => opticalzoom, :product_type => product_type, :date => date)
                ds.save
                ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "orders", :value_flt => orders, :product_type => product_type, :date => date)
                ds.save
                # categorical features
                ds = DailySpec.new(:spec_type => "cat", :sku => sku, :name => "brand", :value_txt => brand, :product_type => product_type, :date => date)
                ds.save
                # binary features
                ds = DailySpec.new(:spec_type => "bin", :sku => sku, :name => "featured", :value_bin => featured, :product_type => product_type, :date => date)
                ds.save
                ds = DailySpec.new(:spec_type => "bin", :sku => sku, :name => "onsale", :value_bin => onsale, :product_type => product_type, :date => date)
                ds.save
              end

            
            
         #  to_write=sku.to_s+" "+u.value.to_s+" "+orders.to_s+" "+product.product_type
         #  add_on=""
         #  if product.product_type=="camera_bestbuy"
         #    add_on=" "+product.cont_specs.find_by_name("saleprice_factor").value.to_s+
         #           " "+product.cont_specs.find_by_name("maxresolution_factor").value.to_s+
         #           " "+product.cont_specs.find_by_name("opticalzoom_factor").value.to_s+
         #           " "+product.cont_specs.find_by_name("brand_factor").value.to_s+
         #           " "+product.cont_specs.find_by_name("onsale_factor").value.to_s+
         #           " "+product.cont_specs.find_by_name("orders_factor").value.to_s                         
         #  end
         #  if product.product_type=="drive_bestbuy"
         #    add_on=" "+product.cont_specs.find_by_name("saleprice_factor").value.to_s+
         #           " "+product.cont_specs.find_by_name("brand_factor").value.to_s+
         #           " "+product.cont_specs.find_by_name("onsale_factor").value.to_s+
         #           " "+product.cont_specs.find_by_name("capacity_factor").value.to_s+                           
         #           " "+product.cont_specs.find_by_name("orders_factor").value.to_s
         #  end
         #  
         #   today_data.write(to_write+add_on+"\n")
         #   cumullative.write(then_date+" "+to_write+add_on+"\n")

          end
        #  today_data.close()
        #  cumullative.close()
        end
  # ******************************************
      end 
      process_everything = true
      unless process_everything
        break; #Only process the first email, unless that email is a weekly email
      end
    end 
  end 
  imap.close
end