# frozen_string_literal: true

require_relative 'helper'
include Helper
require_relative 'actionUnits'
include ActionUnits

headers = File.read('openface-headers').split(',').map(&:strip)

output_headers = select_headers(headers)
@last_action = Time.now
@previous_values = {}
overview = []

file = File.read('test.csv')
file.split("\n").each do |line|
  @values = {}

  action_by_intensity(line, headers, 0.0)
end
