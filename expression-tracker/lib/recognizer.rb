# frozen_string_literal: true

# Class for identifying OpenFace Action Units
class Recognizer
  TIME_INTERVAL = 0.2 # Originally 1.3
  COMBO_TIMEOUT = 2.0

  ACTION_UNITS =  {
    AU01: 'Inner brow raiser',
    AU02: 'Outer brow raiser',
    AU04: 'Brow lowerer',
    AU05: 'Upper lid raiser',
    AU06: 'Cheek raiser',
    AU07: 'Lid tightener',
    AU09: 'Nose wrinkler',
    AU10: 'Upper lip raiser',
    AU12: 'Lip corner puller',
    AU14: 'Dimpler',
    AU15: 'Lip corner depressor',
    AU17: 'Chin raiser',
    AU20: 'Lip stretcher',
    AU23: 'Lip tightener',
    AU25: 'Lips part',
    AU26: 'Jaw drop',
    AU28: 'Lip suck',
    AU45: 'Blink'
  }.freeze

  COMBOS = {
    [:AU02, :AU02] => :DOUBLE_EYEBROW_RAISE,
    [:AU12, :AU12] => :DOUBLE_LIP_PULL,
    [:AU12, :AU12, :AU02] => :LIP_LIP_BROW,
    [:AU02, :AU02, :AU12] => :BROW_BROW_LIP,
  }.freeze

  def initialize
    @last_action = 0
    @combo = []
  end

  def register_callback(&block)
    @callback = block
  end

  def recognize(values)
    return unless values['success'] > 0.9 && values['confidence'] > 0.92
    time_since_last_action = values['timestamp'] - @last_action
    puts "#{values['AU12_r']} #{values['timestamp']} #{time_since_last_action}" if ENV['DEBUG']
    if @last_action == 0 || time_since_last_action.between?(TIME_INTERVAL, COMBO_TIMEOUT)
      puts 'action between' if ENV['DEBUG']
      if au = action_unit(values)
        puts 'au', au if ENV['DEBUG']
        @last_action = values['timestamp']
        @combo << au
      end
    elsif time_since_last_action > COMBO_TIMEOUT && !@combo.empty?
      @callback.call(COMBOS[@combo] || @combo.first)
      @combo = []
    end
  end

  def action_unit(values)
    if values['AU02_r'] > 3.5
      :AU02
    elsif values['AU12_r'] > 2.5
      :AU12
    end
  end
end
