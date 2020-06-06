# frozen_string_literal: true

require_relative 'helper'
include Helper
require_relative 'action_unit'
include ActionUnit

headers = File.read('openface-headers').split(',').map(&:strip)

output_headers = select_headers(headers)
@last_action = Time.now
@previous_values = {}

file = File.read('test.csv')
file.split("\n").each do |line|
  @values = {}
  line.split(',').map(&:to_f).each_with_index { |n, i| @values[headers[i]] = n }

  action_by_intensity(0.0)
end
