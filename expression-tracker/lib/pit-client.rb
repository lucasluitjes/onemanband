# frozen_string_literal: true

require 'paho-mqtt'
require 'json'

class PIT
end

class PIT::Client
  # PIT MQTT Client abstraction. Provides publish and subscribe methods
  # for default topics. Users can grab the @client for custom stuff.
  TOPIC = 'PIT'
  CONFIG = {
    host: 'localhost',
    port: 1883,
    ssl: false,
    topic: TOPIC,
    persistent: true,
    restore: false,
    retain: false,
    qos: 1,
    subscriptions: [],
    parser: true
  }.freeze

  def initialize(type, id, config = {}, &block)
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
    @topic = [@config[:topic], @type, @id]

    # Connect and subscribe to default default topics.
    @client.connect
    log("MQTT Connected to #{@config[:host]}")

    if block
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
  end

  def parse(payload)
    # A valid PIT message can be parsed as JSON into a Hash.
    begin
      parsed = JSON[payload]
    rescue StandardError
      log("Unparseble payload. Not JSON: #{payload}")
    end

    parsed if parsed.is_a?(Hash)
  end

  # Where a logger could be.
  def log(*args)
    puts *args
  end

  # Full topic to string. Want something else? Do it yourself!
  def topic
    @topic.join('/')
  end

  def subscribe; end

  def publish(message)
    log("Publishing on #{topic}")

    @client.publish(topic, message, @config[:retain], @config[:qos])
  end
end

class PIT::Expressor < PIT::Client
  TYPE = 'Expressor'

  def initialize(id, config = {})
    super(TYPE, id, config)
  end
end

class PIT::Actor < PIT::Client
  TYPE = 'Actor'

  def initialize(id, config = {})
    super(TYPE, id, config)
  end
end
