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

@actions = {:AU02 => 'Page_Up', :AU12 => 'Page_Down'}
@recognizer = Recognizer.new
@recognizer.register_callback do |action_unit|
  xdo_key(@actions[action_unit]) 
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
