require 'csv'
require 'pry'
require_relative 'spec_helper'
require_relative '../lib/recognizer'

module Helpers
  def read_fixtures filename
    path = File.join(File.dirname(__FILE__), 'fixtures', filename)
    keys = CSV.open(path, &:readline).map(&:strip)
    fixtures = CSV.read(path, { converters: :numeric})
    fixtures.shift
    fixtures.map {|a| Hash[ keys.zip(a) ] }
  end
end

RSpec.configure do |c|
  c.include Helpers
end

describe 'single actions' do
  it "recognizes a eyebrow raise" do
    fixtures = read_fixtures 'mixed.csv'
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[230..246].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:AU02])
  end

  it "recognizes a lip stretch" do
    fixtures = read_fixtures 'mixed.csv'
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[269..283].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:AU12])
  end

  it "recognizes a series of AUs" do
    fixtures = read_fixtures 'mixed.csv'
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[292..314].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:AU12, :AU12, :AU02])
  end

  it "does not recognize weak signal" do
    fixtures = read_fixtures 'mixed.csv'
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[364..396].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([])
  end
end
