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
  opts.banner = "Usage: server.rb [options]"

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
  :ROW_LIP_BROW => 'Control_L+Tab',
  :LIP_BROW_LIP => 'Control_L+Shift_L+Tab'
}

@recognizer = Recognizer.new
@recognizer.register_callback do |action_unit|
  action = @actions[action_unit]
  if action
    xdo_key(action)
  else
    puts "\n\n#{'-' * 40}\n#{action_unit}\n#{'-' * 40}\n\n"   
  end
end

def handle_message(message)
	@values = message	
	
  @recognizer.recognize(message)
end

def debug_line(line)
		puts "\n\n"
		pp @values

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
