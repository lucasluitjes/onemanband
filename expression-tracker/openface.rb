# frozen_string_literal: true
require 'open3'
require 'json'
require_relative 'openface/helper'
include Helper

def run_openface(publish)
	# Always write to output.csv	
	Thread.new { `./build/bin/FeatureExtraction -device 0 -aus -2Dfp -3Dfp -pdmparams -pose -gaze -of output.csv` }
	sleep 5

	headers = File.read('openface/headers').split(',').map(&:strip)
	STDOUT.sync = true

	# idxssses of headers to output.
	output_headers = select_headers(headers)
	counter = 0
	@last_action = Time.now
	@previous_values = {}

	# Simply tail output.csv and either publish on MQTT or print to STDOUT.
	Open3.popen3('tail -f processed/output.csv') do |_stdin, stdout, _stderr, _wait_thr|
		stdout.each_line do |line|
			@values = {}
			line.split(',').map(&:to_f).each_with_index { |n, i| @values[headers[i]] = n }

			reduced      = Hash[output_headers.map { |n| [headers[n], @values[headers[n]]] }]
			reduced_line = JSON[reduced]
		
			if @options[:mqtt]

				publish(reduced_line)
			else
				puts reduced_line
			end
		end
	end
end
