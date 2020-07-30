# frozen_string_literal: true

require 'pp'
require 'open3'
require 'json'
require_relative 'helper'
include Helper
require_relative 'lib/recognizer'
require_relative 'lib/pit-client'
require 'optparse'

@client
@options = {
  mqtt: false,
  host: 'localhost'
}
OptionParser.new do |opts|
  opts.banner = "Usage: actor.rb [options]"

  opts.on("-m", "--mqtt", TrueClass, "Use MQTT") do |i|
    @options[:mqtt] = true
  end

  opts.on("-h", "--host HOST", "localhost", "Specify mqtt hostname") do |i|
  	@options[:host] = i
  end
end.parse!

@last_action = Time.now
@previous_values = {}

@actions = {
  :DOUBLE_EYEBROW_RAISE => 'Page_Up',
  :DOUBLE_LIP_PULL => 'Page_Down',
  :LIP_LIP_BROW => 'Up',
  :BROW_BROW_LIP => 'Control_L+F4',
  :BROW_LIP_BROW => 'Control_L+Tab',
  :LIP_BROW_LIP => 'Control_L+Shift_L+Tab',
  :BROW_LIP => 'scrolling_loop_up',
  :LIP_BROW => 'scrolling_loop_down',
  :BROW_LIP_LIP => 'scrolling_loop_reset'
}

@intervals = [-0.1, -0.25, -0.5, -1, 0, 1, 0.5, 0.25, 0.1]
@scroll_speed = @intervals.index(0)
@paused
Thread.new {pausing}
Thread.new {scrolling}

@recognizer = Recognizer.new
@recognizer.register_callback do |action_unit|
  action = @actions[action_unit]
  if action
    if action.include?('scrolling_loop')
      case action.split('_').last
      when 'up'
        @scroll_speed += 1 unless @scroll_speed == @intervals.size - 1
      when 'down'
        @scroll_speed -= 1 unless @scroll_speed == 0
      when 'reset'
        @scroll_speed = @intervals.index(0)
      else
        raise
      end
    else
      xdo_key(action)
    end
  else
    puts "\n\n#{'-' * 40}\n#{action_unit}\n#{'-' * 40}\n\n"   
  end
end

def handle_message(message)
	@values = message	
	
  @recognizer.recognize(message) unless @paused
end

def debug_line(line)
		puts "\n\n"
		pp @values
end

def pausing
  _stdin, stdout, _stderr, _wait_thr = Open3.popen3('xinput test-xi2 --root')

  event = nil
  stdout.each do |line|
    event = line.split.last if line.include?('EVENT type')
    next unless line.include?('detail:')

    keypress = line.split[1]
    if event == '(KeyRelease)' && keypress.to_i == 69
      @paused = !@paused
      event = nil
    end
  end
end

def scrolling
  last_scroll = Time.now.to_f
  loop do
    sleep 0.5
    vec = @intervals[@scroll_speed] # scroll speed and direction
    next if vec == 0

    since_last_scroll = Time.now.to_f - last_scroll
    # puts vec
    if since_last_scroll > vec.abs
      xdo_key("#{vec.positive? ? 111 : 116}")
      last_scroll = Time.now.to_f
    end
  end
end

# Counter is for debug purposes only.
@counter = 0
if @options[:mqtt]
		config = {
			:subscriptions=>[
			  ["PIT/Expressor/OpenFace", 1], ["PIT/Expressor/Feetsboard", 2]
      ],
      :host => @options[:host]
    }

		@client = PIT::Actor.new "OpenFace", config do |message|
			#require 'pry'
			#binding.pry
			handle_message(message)
			debug_line(message) if (@counter += 1) % 8 == 0
		end
else # STDIN put.
	while line = STDIN.gets
		handle_message(line)
		debug_line(line) if (@counter += 1) % 8 == 0
	end
end

# Sleep because the client does not.
sleep
