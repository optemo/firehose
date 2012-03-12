def save_daily_pageviews
  require 'net/imap'
  require 'zip/zip'
  imap = Net::IMAP.new('imap.1and1.com') 
  imap.login('files@optemo.com', '***REMOVED***') 
  imap.select('INBOX') 
  only_last=false    #only process the last email
  # All msgs in a folder 
  # Oct 29, 2011 is the earliset date for page views
  msgs = imap.search(["SINCE", "29-Jan-2012","BEFORE", "30-Jan-2012"])
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
        cName = "#{Rails.root}/tmp/pageviews-#{then_date}.zip" 
        
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
             f_path=File.join("#{Rails.root}/tmp/pageviews/", f.name)
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
          
          #### THIS DOES THE PROCESSING OF THE CSV FILE
          views_map = {} # map of sku => views
          
          File.open(csvfile, 'r') do |f|
            f.each do |line|
              /\d+\.,,(?<sku>[^,N]{8}),,"?(?<views>\d+(,\d+)*)"?.+/ =~ line
              views_map[sku] = views if sku
            end
          end
          date = then_date.prev_day().strftime("%Y-%m-%d")
          #only select the products that have some existing spec in the daily spec table for that day
          products = DailySpec.where(:date => date).select("DISTINCT(sku)")
          products.each do |prod_sku|
            sku = prod_sku.sku
            product_type = DailySpec.find_by_sku_and_value_txt(sku, nil).product_type
            views_spec = views_map[sku]
            views = (views_spec.nil?) ? "0" : views_spec.delete(',') # Otherwise to_i will only return characters before first comma
            # write views to daily_sales for the date and the sku
            ds = DailySpec.new(:spec_type => "cont", :sku => sku, :name => "pageviews", :value_flt => views, :product_type => product_type, :date => date)
            ds.save
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