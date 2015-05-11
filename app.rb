require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'erubis'
require 'securerandom'
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN

set :server, 'thin'
set :sockets, []
set :bind, '0.0.0.0'
set :port, 4567

get '/' do
  if !request.websocket?
    erb :index
  else
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
        ws.send( JSON.dump( get_state ) )
      end
      ws.onmessage do |msg|
        begin
          parsed = JSON.parse( msg )
          if parsed["command"] == "open"
            EM.next_tick {
              settings.sockets.each{|s| s.send( JSON.dump( execute_osa_start_command(parsed) ) ) }
            }
          elsif parsed["command"] == "next"
            EM.next_tick {
              settings.sockets.each{|s| s.send( JSON.dump( execute_osa_next_command(parsed) ) ) }
            }
          elsif parsed["command"] == "prev"
            EM.next_tick {
              settings.sockets.each{|s| s.send( JSON.dump( execute_osa_prev_command(parsed) ) ) }
            }
          elsif parsed["command"] == "stop"
            EM.next_tick {
              settings.sockets.each{|s| s.send( JSON.dump( execute_osa_stop_command(parsed) ) ) }
            }
          else
            puts "WARN: unknown command #{parsed['command']}"
          end
        rescue Exception => e
          puts "Error while handling input: #{e}"
        end
      end
      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end

private

def get_state
  keynote_state = get_keynote_state
  keynote_state_file = { :name => nil, :slide => nil, :total => nil }
  if keynote_state[:cmd_state] == :success
    if keynote_state[:state] =~ /ok:.*/
      _, file, slide, total = keynote_state[:state].split(":")
      keynote_state_file = { :name => file, :slide => slide, :total => total }
      logger.info "Keynote state valid: #{keynote_state_file}"
    else
      logger.info "Keynote state: #{keynote_state[:state]}."
    end
  else
    logger.info "Keynote state failed: #{keynote_state[:error]}."
  end
  files = Dir["#{File.expand_path(File.dirname(__FILE__))}/presos/*.key"].map {|s|
    base_name = File.basename(s)
    if base_name == keynote_state_file[:name]
      { :path => s, :name => base_name, :r => true, :slide => keynote_state_file[:slide], :total => keynote_state_file[:total] }
    else
      { :path => s, :name => base_name, :r => false }
    end
  }
  logger.info "Returning initial state information."
  { :response => "state", :presos => files }
end

def get_keynote_state
  logger.info "Attempting to execute Keynote state command..."
  template = Erubis::Eruby.new(File.read("#{File.expand_path(File.dirname(__FILE__))}/commands/keynote_state.applescript.erb"))
  template_result = template.result
  file_name = "/tmp/#{SecureRandom.uuid().to_s}.applescript"
  File.write(file_name, template_result.to_s)
  cmdresult = `cat #{file_name} | $(which osascript)`.chomp
  File.delete(file_name)
  code = $?.exitstatus
  if code == 0
    logger.info "Keynote state accessed successfully."
    { :cmd_state => :success, :state => cmdresult }
  else
    logger.error "Could not load Keynote state. Reason: #{cmdresult}, error code: #{code}"
    { :cmd_state => :failed, :error => cmdresult, :code => code }
  end
end

def execute_osa_start_command input
  logger.info "Attempting to execute presentation start command..."
  template = Erubis::Eruby.new(File.read("#{File.expand_path(File.dirname(__FILE__))}/commands/start.applescript.erb"))
  template_result = template.result(:file_path => input["path"])
  file_name = "/tmp/#{SecureRandom.uuid().to_s}.applescript"
  File.write(file_name, template_result.to_s)
  cmdresult = `cat #{file_name} | $(which osascript)`.chomp
  File.delete(file_name)

  code = $?.exitstatus
  if code == 0
    logger.info "Presentation opened successfully."
    { :response => "opened", :path => input["path"], :name => input["name"], :slides => cmdresult }
  else
    logger.error "Could not open the presentation. Reason: #{cmdresult}, exit code #{code}"
    { :response => :failed, :command => input["command"], :error => cmdresult, :code => code }
  end
end

def execute_osa_next_command input
  logger.info "Attempting progressing to the next slide. (current slide: #{input["current"]})"
  template = Erubis::Eruby.new(File.read("#{File.expand_path(File.dirname(__FILE__))}/commands/next.applescript.erb"))
  template_result = template.result( :current => input["current"] )
  file_name = "/tmp/#{SecureRandom.uuid().to_s}.applescript"
  File.write(file_name, template_result.to_s)
  cmdresult = `cat #{file_name} | $(which osascript)`.chomp
  File.delete(file_name)

  code = $?.exitstatus
  if code == 0
    { :response => "changed", :document => input["document"], :slide => cmdresult }
  else
    logger.error "Could not progress to the next slide. Reason: #{cmdresult}, exit code #{code}"
    { :response => :failed, :command => input["command"], :error => cmdresult, :code => code }
  end
end

def execute_osa_prev_command input
  logger.info "Attempting going back to the previous slide (current slide: #{input["current"]})."
  template = Erubis::Eruby.new(File.read("#{File.expand_path(File.dirname(__FILE__))}/commands/prev.applescript.erb"))
  template_result = template.result( :current => input["current"] )
  file_name = "/tmp/#{SecureRandom.uuid().to_s}.applescript"
  File.write(file_name, template_result.to_s)
  cmdresult = `cat #{file_name} | $(which osascript)`.chomp
  File.delete(file_name)
  
  code = $?.exitstatus
  if code == 0
    { :response => "changed", :document => input["document"], :slide => cmdresult }
  else
    logger.error "Could not go back to the previous slide. Reason: #{cmdresult}, exit code #{code}"
    { :response => :failed, :command => input["command"], :error => cmdresult, :code => code }
  end
end

def execute_osa_stop_command input
  logger.info "Attempting to stop Keynote...."
  template = Erubis::Eruby.new(File.read("#{File.expand_path(File.dirname(__FILE__))}/commands/stop.applescript.erb"))
  template_result = template.result
  file_name = "/tmp/#{SecureRandom.uuid().to_s}.applescript"
  File.write(file_name, template_result.to_s)
  cmdresult = `cat #{file_name} | $(which osascript)`.chomp
  File.delete(file_name)
  code = $?.exitstatus
  if code == 0
    { :response => "quit" }
  else
    logger.error "Could not stop Keynote. Reason: #{cmdresult}, exit code #{code}"
    { :response => :failed, :command => input["command"], :error => cmdresult, :code => code }
  end 
end