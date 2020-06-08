# frozen_string_literal: true

require 'pp'
require 'open3'
require 'json'
require 'mqtt'
require_relative 'helper'
include Helper
require_relative 'action_unit'
include ActionUnit

mqtt = false
mqtt_broker = ENV["MQTT_BROKER"] || "mqtt://localhost"
mqtt_topic  = ENV["MQTT_TOPIC"]  || "PIT"

# Do we need to connect to MQTT?
if ARGV[0] == "--mqtt"
	mqtt = true
	mqtt_client = MQTT::Client.connect(mqtt_broker)
	puts "MQTT connected: " + mqtt_broker + "/" + mqtt_topic
end

@last_action = Time.now
@previous_values = {}
def handle_message(message)
	@values = JSON.parse(message)
	
	action_by_intensity(1.3)
end

def debug_line(line)
		puts "\n\n"
		pp @values

end

# Counter is for debug purposes only.
counter = 0
if mqtt # mqqt input.
	mqtt_client.get(mqtt_topic) do |topic, message|
		handle_message(message)	
		debug_line(message) unless (counter += 1) % 8 == 0
	end
else # STDIN put.
	while line = STDIN.gets
		handle_message(line)
		debug_line(line) unless (counter += 1) % 8 == 0
	end
end

