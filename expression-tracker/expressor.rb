# frozen_string_literal: true

require 'open3'
require 'json'
require_relative 'helper'
include Helper
require_relative 'lib/pit-client'
require 'optparse'

@client
@options = {
  mqtt: false,
  timeout: 1200
}
OptionParser.new do |opts|
  opts.banner = 'Usage: expressor.rb [options]'

  opts.on('-m', '--mqtt', TrueClass, 'Use MQTT') do |_i|
    @options[:mqtt] = true
  end
end.parse!

@client = PIT::Expressor.new 'OpenFace' if @options[:mqtt]

headers = File.read('openface-headers').split(',').map(&:strip)
STDOUT.sync = true

# idxssses of headers to output.
output_headers = select_headers(headers)
counter = 0
@last_action = Time.now
@previous_values = {}
@processing = false

unless File.exist?('processed/output.csv')
  `ln -s /dev/stdout processed/output.csv`
end
cmd = './build/bin/FeatureExtraction -device 0 -aus -2Dfp -3Dfp -pdmparams -pose -gaze -of output.csv'
Open3.popen3(cmd) do |_stdin, stdout, _stderr, wait_thr|
  if @options[:timeout] != 0
    Thread.new { sleep @options[:timeout]; `kill #{wait_thr.pid}`; exit }
  end
  stdout.each_line do |line|
    if @processing
      @values = {}
      line.split(',').map(&:to_f).each_with_index { |n, i| @values[headers[i]] = n }

      reduced      = Hash[output_headers.map { |n| [headers[n], @values[headers[n]]] }]
      reduced_line = JSON[reduced]

      if @options[:mqtt]

        @client.publish(reduced_line)
      else
        puts reduced_line
      end
    elsif line.include?('frame, face_id, timestamp, confidence, success')
      @processing = true
    end
  end
end
