def read_daily_sales
  require 'net/imap'
  require 'zip/zip'
  imap = Net::IMAP.new('imap.1and1.com') 
  imap.login('files@optemo.com', '***REMOVED***') 
  imap.select('Inbox') 
  # All msgs in a folder 
  msgs = imap.search(["SINCE", "1-Jan-1969"]) 
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
        unless csvfile.blank?
          
          #./tmp/Daily_Data my not exist as a directory
          %x{mkdir ./tmp/Daily_Data}
          
          today_data=File.open("./tmp/Daily_Data/"+Time.now.to_s[0..9]+".txt",'w')
          cumullative=File.open("./tmp/Daily_Data/Cumullative_Data.txt",'a')
          File.open(csvfile, 'r') do |f|
            f.each do |line|
              /\d+\.,,(?<sku>[^,]+),,(?<rev>"?\$\d+(,\d+)?"?),,,,[^,]+,,(?<orders>\d+)/ =~ line
              if sku
                product = Product.find_by_sku(sku)
                if product && product.instock
                  u=product.cont_specs.find_by_name("utility")
                  today_data.write(sku.to_s+" "+u.value.to_s+" "+orders.to_s+"\n")
                  cumullative.write(Time.now.to_s[0..9]+" "+sku.to_s+" "+u.value.to_s+" "+orders.to_s+"\n")
                end
              end
            end
          end
          today_data.close()
          cumullative.close()
        end
  # ******************************************
      end 
      break; #Only process the first email
    end 
  end 
  imap.close
end
