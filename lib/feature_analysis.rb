#$data_path = "/Users/oana/AeroFS/jan's Library/BestBuy/processed_daily_data/"


def generate_daily_graphs()
  puts "Saving files: "
  Dir.foreach($data_path) do |entry|
    if entry =~ /\.txt/
      puts "processing file " + entry
      process('camera_bestbuy', entry)
      process('drive_bestbuy', entry)      
    end
  end
  
end

def process(type, in_fname)
  out_path = "../../log/Daily_Data/processed/"
  FileUtils.mkdir_p(out_path) unless File.directory?(out_path)
  
  fname = $data_path + in_fname
  f = File.open(fname, "r")
  outfile_name = out_path + type + "_" + in_fname
  outfile = File.new(outfile_name, "w")
  lines = f.readlines
  
  f.close()
  output_lines = ""
  
  lines.each do |line|
    #if line =~ /camera_bestbuy/
    if line =~ /#{type}/
      outfile.write(line)
    end
  end
    
  outfile.close()
  # call draw_plot with that new file as the input
  #draw_plot(outfile_name)
  puts outfile_name
  
  file_name = type + "_" + in_fname

end

