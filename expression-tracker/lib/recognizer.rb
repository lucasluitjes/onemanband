class Recognizer
  TIME_INTERVAL=1.3

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

  def initialize
    @last_action = 0
  end

  def register_callback &block
    @callback = block
  end 

  def recognize values
    if values['success'] > 0.9 && values['confidence'] > 0.92
      if (values['timestamp'] - @last_action) > TIME_INTERVAL
        if values['AU02_r'] > 3.3
          @last_action = values['timestamp']
          @callback.call :AU02
        elsif values['AU12_r'] > 2.1
          @last_action = values['timestamp']
          @callback.call :AU12
        end
      end
    end
  end
end
