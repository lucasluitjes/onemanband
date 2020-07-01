# frozen_string_literal: true

require 'open3'
require 'json'
require_relative 'openface'
require_relative 'lib/pit-client'

pit_client = PIT::Client.new "expressor", "openface"
pit_client.start &method(:run_openface)
pit_client.stop  &method(:stop_openface)
pit_client.run
