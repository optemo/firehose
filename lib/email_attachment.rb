def product_orders
  require 'net/imap'
  require 'zip/zip'
  imap = Net::IMAP.new('imap.1and1.com') 
  imap.login('auto@optemo.com', '***REMOVED***') 
  imap.select('Inbox') 
  # All msgs in a folder 
  msgs = imap.search(["SINCE", "1-Jan-1969"]) 
  # Read each message 
  msgs.reverse.each do |msgID| 
    msg = imap.fetch(msgID, ["ENVELOPE","UID","BODY"] )[0] 
  # Only those with 'SOMETEXT' in subject are of our interest 
    if msg.attr["ENVELOPE"].subject.index('Products Report') != nil 
      body = msg.attr["BODY"] 
      i = 1 
      while body.parts[i] != nil 
  # additional attachments attributes 
        i+=1 
        next if body.parts[i-1].param.nil? || body.parts[i-1].media_type.nil?
        cType = body.parts[i-1].media_type 
        cName = "#{Rails.root}/tmp/"+body.parts[i-1].param['NAME'] 
        
  # fetch attachment. 
        attachment = imap.fetch(msgID, "BODY[#{i}]")[0].attr["BODY[#{i}]"] 
  # Save message, BASE64 decoded 
        File.open(cName,'wb+') do |f|
          f.write(attachment.unpack('m')[0])
        end
  # Unzip file
        #I coulnd't figure out how to unzip a string, otherwise we could do this whole thing in memory instead of temp files
        Zip::ZipFile.open(cName) do |zip_file|
           zip_file.each do |f|
             f_path=File.join("#{Rails.root}/tmp/", f.name)
             FileUtils.mkdir_p(File.dirname(f_path))
             zip_file.extract(f, f_path) unless File.exist?(f_path)
           end
         end
  # Open csv file
        contspecs = []
        File.open(cName.gsub('.zip','.csv'), 'r') do |f|
          f.each do |line|
            /\d+\.,,(?<sku>[^,]+),,(?<rev>"?\$\d+(,\d+)?"?),,,,[^,]+,,(?<orders>\d+)/ =~ line
            if sku
              product = Product.find_by_sku(sku)
              if product
                contspec = ContSpec.find_by_product_id_and_name_and_product_type(product.id, "orders", product.product_type) || ContSpec.new(:name => "orders", :product_type => product.product_type, :product_id => product.id)
                contspec.value = orders
                contspecs << contspec
              end
            end
          end
        end
  # Save Cont specs
        ContSpec.import contspecs, :on_duplicate_key_update=>[:product_id, :name, :value, :modified] if contspecs.size > 0
      end 
      break; #Only process the first email
    end 
  end 
  imap.close
end