require 'paho-mqtt'
require 'json'

class PIT
end

class PIT::Client
	# PIT Client abstraction. Provides generic interface to create a PIT client 
	# producing/consuming PIT network messages (expressions). Implementation input/output
	# is wrapped in meta-object supporting control messages for PIT client lifecycle
	# methods: start, stop.

	def initialize(type, id, subscriptions=[], &block)
		TOPIC = "PIT" # Hardcoded topic root.
		
		# This allows mqqt client config to be controlled by the user. Ideally we don't want to bother
		# the user with this and, I suggest, read it from an (optional) config file. Hardcoding network
		# configuration is simply icky and gross. And when SSL is used certs/files are to be supplied 
		# anyway, reading from file it is. (I just don't feel like implementing that boring part now)
		attr_accessor :mqtt_config
		@mqtt_config = {}

		@type = type
		@id = id

		# We are an abstraction away from MQTT and other implementation details we don't want/have to
		# bother our users with. So we're very friendly and accept most forms of subscriptions here. 
		# What we would like the user to input is a list of [type,id]. E.g.: 
		# [['expressor', 'openface'], ['expressor', 'speech']]
		# The users does not have to worry about the correct topic root or seperator. But we also accept:
		# ['expressor/openface', 'expressor/speech']
		# Because programmers are smarty pants who think they know the topic seperator. And so, we also accept:
		# ['PIT/expressor/openface', 'PIT/expressor/speech'], or [['PIT', 'expressor', 'openface']]
		# Because the same smarty pants will also know the topic root and forget about all this fancy abstraction.
		# here we go.
		@subscriptions = subscriptions.map { |s| (s.join("/") if s.is_a? Array else s).gsub(/^#{TOPIC}/, '') }
		
		@start_block = block
		# Auto run if user provided &block in constructor.
		invoke_start block if @start_block
	end
		
	def start(&block)
		# User can provide start block through constructor for autostart, or through this method
		# after creation. This method will not actually start the client or messages.
		@start_block = block
	end
	
	def stop(&block)
		# User can optionally provide a stop block for them to gracefully stop and clean up whatever
		# they were doing. Otherwise, or, either way after a timeout, the thread the user implementation
		# was running in is going to be killed by us. The controller of such things.
		@stop_block = block
	end
	
	def receive(&block)
		# Callback on message received on any of the subscriptions.
		@receive_block = block
	end

	def publish(message)
		# Wrap payload in control structure. Only a payload will suffice.
		return {:payload=>message}
	end
	
	def parse(message)
		# This is where we receive control structure messages and can do things like:
		return invoke_stop  if message[:signal] == "stop"
		return invoke_start if message[:signal] == "start"
		# Or, if no applicable control message found, pass on the payload.
		return message[:payload]
	end

	def invoke_start()
			# Start MQTT client, subscribe to messages and parse control structure, 
			# call user block and provide wrapped publish function. Something like:
			@client = PIT::Network::Client.new @type, @id
			@thread = Thread.new { 
				@start_block.call(publish)
			}
			@client.subscribe @subscriptions, do |message| @receive_block.call(parse(message))
	end

	def invoke_stop()
		# Allow user implementation to clean up, and then kill thread either way after timeout.
			@thread.terminate
	end

	def run()
		raise "Nothing to start/run" if not @start_block or invoke_start
	end
end

class PIT::Network::Client
	# MQTT Client abstraction. Standardized topic using TOPIC/type/id. 
	# Provides generic publish/subscribe interface with JSON payload.

	TOPIC = "PIT"
	CONFIG = {
		:host=>"localhost",
		:port=>1883,
		:ssl=>false,
		:topic=>TOPIC,
		:persistent=>true,
		:restore=>false,
		:retain=>false,
		:qos=>1,
		:subscriptions=>[],
		:parser=>true
	}
	
	def initialize(type, id, config={}, &block)
		@type = type
		@id = id
		@config = CONFIG.merge config
		@client = PahoMqtt::Client.new({
			host: @config[:host],
			port: @config[:port],
			ssl: @config[:ssl],
			persistent: @config[:persistent],
			clean_session: !@config[:restore] # Asks broker to restore session
		})
		
		# Create full topic as array to select from, build with. 
		@topic = [@config[:topic],@type,@id]

		# Connect and subscribe to default default topics.
		@client.connect
		log("MQTT Connected to #{@config[:host]}")
	
		subscribe(@config[:subscriptions], block) if block
	end
	
	def parse(payload)
		# A valid PIT message can be parsed as JSON into a Hash.
		begin
			parsed = JSON[payload]
		rescue
			log("Unparseble payload. Not JSON: #{payload}")
		end
		
		parsed if parsed.is_a?(Hash)
	end

	# Where a logger could be.
	def log(*args)
		puts "[#{self.class.name}] " + *args
	end
	
	# Topic to string.
	def topic
		@topic.join("/")
	end

	def subscribe(topics, &block)
		log("Subscribing to #{@config[:subscriptions]}")
		@client.subscribe @config[:subscriptions]
		@client.on_message do |message| 
			# Call block with (successfully) parsed message payload, or message.
			if @config[:parser]
				parsed = parse(message.payload)
				block.call(parsed) if parsed
			else
				block.call(message)
			end
		end
	end

	def publish(message)
		log("Publishing on #{topic}")

		@client.publish(topic, message, @config[:retain], @config[:qos])
	end
end

class PIT::Expressor < PIT::Client
	TYPE = "Expressor"

	def initialize(id, config={})
		super(TYPE, id, config)
	end
end

class PIT::Actor < PIT::Client
	TYPE = "Actor"

	def initialize(id, config={})
		super(TYPE, id, config)
	end
end

