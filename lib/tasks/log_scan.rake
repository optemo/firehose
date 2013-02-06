#scan log file for errors, keep track of last place in the log file, email alert if error has occured
#call task with format: rake error_scan logpath="/Users/username/Desktop/crontab.log" 
desc:"search log file for rake aborted! to find major errors"
task :error_scan => [:environment] do
  #get path of log file
  file_path = ENV['logpath']
  file_path_name = Pathname.new(file_path)
  if file_path_name.relative?
    file_path = file_path_name.realpath.to_s
  end

  most_recent_date, previous_date, email_body_text, previous_line, appname = ""
  line_number = 1
  reached_previous_date = false
  current_time = Time.new
  #get appname
  path_array = file_path.split('/')
  if path_array.length > 3
    if path_array[1].match('u') && path_array[2].match('apps')
      appname = path_array[3]
    end
  end
  
  #add timestamp to end of file
  File.open(file_path, 'a') do |s|
    s.puts "\nLOGSCAN: " + current_time.to_s
  end
  
  #get previous timestamp
  log_file = File.open(file_path).each do |s|
    if s.match('LOGSCAN: ')
      unless s.split("LOGSCAN: ")[1].match(current_time.to_s)
        previous_date = s.split("LOGSCAN: ")[1]
      end
    end
  end
  
  #read log file
  log_file = File.open(file_path).each
  begin
    while(true) do
      s = log_file.next
      #Start recording once you reach the previous timestamp
      if reached_previous_date == false
        if previous_date.nil?
          reached_previous_date = true
        elsif s.match('LOGSCAN: ') && s.split('LOGSCAN: ')[1].match(previous_date)
          reached_previous_date = true
        end
      end
      #keep track of most recent timestamp for error message
      if s.match(/start: /i)
        most_recent_date = s.split(/start: /i)[1]
      end
      #build the error message to add to the email
      unless s.nil? || reached_previous_date == false
        if s.match('rake aborted!') || s.match('Got the following error in scraping current category')
          unless most_recent_date == ""
            error_text = "An error occured in a task started at " + most_recent_date
          end
          error_text += "At line " + line_number.to_s + " of " + file_path + ", with the message:" + "\n"
          unless previous_line.nil? 
            error_text += previous_line 
          end        
          error_text += s
          #record the next 3 lines after "rake abort!" in the log  
          begin  
            3.times do
              previous_line = log_file.next
              error_text += previous_line
              line_number += 1
            end
          rescue StopIteration
          end
          error_text += "\n\n\n"          
          if email_body_text.nil?
            email_body_text = error_text
          else
            email_body_text += error_text
          end
        end
      end
      line_number += 1
      previous_line = s
    end
  rescue StopIteration
  end

  #send an email alert if errors occured
  unless email_body_text.nil?
    if appname.nil?
      appname = file_path
    end
    LogScanNotifier.send_alert(appname, email_body_text).deliver
  end
end