require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'erubis'
require 'securerandom'

set :server, 'thin'
set :sockets, []
set :bind, '0.0.0.0'

get '/' do
  if !request.websocket?
    erb :index
  else
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
        ws.send( JSON.dump( list_presos ) )
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

def list_presos
  { :response => "presos", :presos => Dir["#{File.expand_path(File.dirname(__FILE__))}/presos/*.key"] }
end

def execute_osa_start_command input
  template = Erubis::Eruby.new(File.read("#{File.expand_path(File.dirname(__FILE__))}/commands/start.applescript.erb"))
  template_result = template.result(:file_path => input["document"])
  file_name = "/tmp/#{SecureRandom.uuid().to_s}.applescript"
  File.write(file_name, template_result.to_s)
  cmdresult = `cat #{file_name} | $(which osascript)`.chomp
  File.delete(file_name)
  if $?.exitstatus == 0
    { :response => "opened", :document => input["document"], :slides => cmdresult }
  else
    { :response => "open_failed", :document => input["document"], :error => cmdresult }
  end
end

def execute_osa_next_command input
  template = Erubis::Eruby.new(File.read("#{File.expand_path(File.dirname(__FILE__))}/commands/next.applescript.erb"))
  template_result = template.result
  file_name = "/tmp/#{SecureRandom.uuid().to_s}.applescript"
  File.write(file_name, template_result.to_s)
  cmdresult = `cat #{file_name} | $(which osascript)`.chomp
  File.delete(file_name)
  if $?.exitstatus == 0
    { :response => "changed", :document => input["document"], :slide => cmdresult }
  else
    { :response => "change_failed", :document => input["document"], :error => cmdresult }
  end
end

def execute_osa_prev_command input
  template = Erubis::Eruby.new(File.read("#{File.expand_path(File.dirname(__FILE__))}/commands/prev.applescript.erb"))
  template_result = template.result
  file_name = "/tmp/#{SecureRandom.uuid().to_s}.applescript"
  File.write(file_name, template_result.to_s)
  cmdresult = `cat #{file_name} | $(which osascript)`.chomp
  File.delete(file_name)
  if $?.exitstatus == 0
    { :response => "changed", :document => input["document"], :slide => cmdresult }
  else
    { :response => "change_failed", :document => input["document"], :error => cmdresult }
  end
end

def execute_osa_stop_command input
  template = Erubis::Eruby.new(File.read("#{File.expand_path(File.dirname(__FILE__))}/commands/stop.applescript.erb"))
  template_result = template.result
  file_name = "/tmp/#{SecureRandom.uuid().to_s}.applescript"
  File.write(file_name, template_result.to_s)
  cmdresult = `cat #{file_name} | $(which osascript)`.chomp
  File.delete(file_name)
  { :response => "quit", :document => input["document"] }
end