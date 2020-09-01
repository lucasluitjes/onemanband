# frozen_string_literal: true

require 'csv'
require 'pry'
require_relative 'spec_helper'
require_relative '../lib/recognizer'

describe 'single actions' do
  it 'recognizes a eyebrow raise' do
    fixtures = read_fixtures 'mixed.csv'
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[230..270].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:AU02])
  end

  it 'recognizes a lip stretch' do
    fixtures = read_fixtures 'mixed.csv'
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[269..300].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:AU12])
  end

  it 'recognizes a series of AUs' do
    fixtures = read_fixtures 'mixed.csv'
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[292..340].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:LIP_LIP_BROW])
  end

  it 'does not recognize weak signal' do
    fixtures = read_fixtures 'mixed.csv'
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[364..396].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([])
  end
end
