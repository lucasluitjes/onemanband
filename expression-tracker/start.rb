# frozen_string_literal: true

require 'pp'
require 'open3'
require_relative 'helper'
include Helper
require_relative 'action_unit'
include ActionUnit

Thread.new { `./build/bin/FeatureExtraction -device 0 -aus -2Dfp -3Dfp -pdmparams -pose -gaze -of output.csv` }
sleep 5

headers = File.read('openface-headers').split(',').map(&:strip)
pp headers
STDOUT.sync = true

output_headers = select_headers(headers)
counter = 0
@last_action = Time.now
@previous_values = {}

Open3.popen3('tail -f processed/output.csv') do |_stdin, stdout, _stderr, _wait_thr|
  stdout.each_line do |line|
    @values = {}
    line.split(',').map(&:to_f).each_with_index { |n, i| @values[headers[i]] = n }

    action_by_intensity(1.3)

    # debug output
    next unless (counter += 1) % 8 == 0

    puts "\n\n"
    output_headers.each { |n| puts "#{headers[n]}: #{@values[headers[n]]}" }
  end
end
