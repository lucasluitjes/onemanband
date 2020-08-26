# frozen_string_literal: true

require 'csv'
require 'pry'
require_relative 'spec_helper'
require_relative '../lib/recognizer'

describe 'combos' do
  let(:fixtures) { read_fixtures 'webcam_2020-06-18-16-56.csv' }

  it 'recognizes a DOUBLE EYEBROW RAISE' do
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[286..330].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:DOUBLE_EYEBROW_RAISE])
  end

  it 'recognizes another DOUBLE EYEBROW RAISE' do
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[423..460].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:DOUBLE_EYEBROW_RAISE])
  end

  it 'recognizes a DOUBLE LIP PULL' do
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[580..620].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:DOUBLE_LIP_PULL])
  end

  it 'recognizes another DOUBLE LIP PULL' do
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[711..750].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:DOUBLE_LIP_PULL])
  end

  it 'recognizes LIP LIP BROW' do
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[871..920].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:LIP_LIP_BROW])
  end

  it 'recognizes another LIP LIP BROW' do
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[1017..1070].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:LIP_LIP_BROW])
  end

  it 'recognizes BROW BROW LIP' do
    recognizer = Recognizer.new
    result = []
    recognizer.register_callback { |b| result << b }
    fixtures[1171..1220].each { |frame| recognizer.recognize(frame) }
    expect(result).to eq([:BROW_BROW_LIP])
  end
end
