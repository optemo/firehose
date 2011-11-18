#$data_path = "/Users/oana/AeroFS/jan's Library/BestBuy/processed_daily_data/"
$data_path = "../../log/Daily_Data/"

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

def plot_points(in_name)

name = in_name.chomp(File.extname(in_name))
print_name = name.gsub(/_/," ")
out_extension = "ps"

command = <<END_HEREDOC.gsub(/\s+/, " ").strip
echo \"
  set terminal x11;
  set xlabel 'Utility';
  set ylabel 'Sales';
  set xrange [0.0:1.0];
  set yrange [0.0:*];
  plot '#{$data_path}#{in_name}' using 2:3 with points lt 3 pt 2 title '#{print_name}';
  set size 1.0, 1.0;
  set terminal postscript landscape enhanced mono dashed lw 1 'Helvetica' 14;
  set output '#{$data_path}#{name}.#{out_extension}';
  replot;
\" | gnuplot
END_HEREDOC

puts "plotting #{$data_path}#{name}.#{out_extension}"

system(command)
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
    if line =~ /#{type}/
      outfile.write(line)
    end
  end
    
  outfile.close()
  file_name = type + "_" + in_fname
  plot_points(file_name)
end
