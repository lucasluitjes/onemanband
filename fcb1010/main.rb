require 'unimidi'
require 'pp'
require 'pry'

# patch
module AlsaRawMIDI
  class Input
    def gets
      until enqueued_messages?
        sleep 0.01
      end
      msgs = enqueued_messages
      @pointer = @buffer.length
      msgs
    end
  end
end

class Reader
  def initialize
    reload_controller
    @input = UniMIDI::Input.use(:first)
    start_loop
  end

  def reload_controller
    @mtime = File.mtime('controller.rb')
    load('./controller.rb')
    @controller = Controller.new
  end

  def start_loop
    File.open('log','w') do |f|
      f.sync = true
      loop do
        begin
          reload_controller unless File.mtime('controller.rb') == @mtime
        rescue SyntaxError => e
          puts e.inspect
          puts e.backtrace
        end
        data = @input.gets_data
        puts "\n" + data.inspect
        # data[0] == 192: button. data[0] == 176: wah pedal
        if data[0] == 192
          raw =  data[1] || 0
          if (Time.now.to_f - @controller.last_input) > 0.4
            f.puts raw / 10
            @controller.process(raw / 10, (raw % 10) + 1)
          end
        end
      end
    end
  end
end

Reader.new
