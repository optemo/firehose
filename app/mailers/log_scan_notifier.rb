class LogScanNotifier < ActionMailer::Base
  default from: "from@example.com"
  
  def send_alert(subject_text, body_text)
    mail(:to => "support@optemo.com", :subject => "Log error on: " + `hostname`.strip.capitalize + " " + subject_text.capitalize, :body => body_text)
  end
end
