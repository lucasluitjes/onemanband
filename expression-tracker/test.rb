require 'pp'
require 'open3'
require_relative 'helper'
include Helper
require_relative 'actionUnits'
include ActionUnits

Thread.new{`./build/bin/FeatureExtraction -device 0 -aus -2Dfp -3Dfp -pdmparams -pose -gaze -of output.csv`}
sleep 5

headers = File.read("openface-headers").split(",").map(&:strip)
pp headers
STDOUT.sync = true

output_headers = select_headers(headers)
counter = 0
@last_action = Time.now
@previous_values = {}
overview = []

Open3.popen3("tail -f processed/output.csv") do |stdin, stdout, stderr, wait_thr|
  stdout.each_line do |line|
    @values = {}

    action_by_intensity(line, headers)

    # debug output
    next unless (counter += 1) % 8 == 0
    puts "\n\n"
    output_headers.each {|n| puts "#{headers[n]}: #{@values[headers[n]]}"}
  end
end
