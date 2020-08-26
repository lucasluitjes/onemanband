# frozen_string_literal: true

module ActionUnit
  #  intensity (from 0 to 5), AU28 does not work with intensity
  def action_by_intensity(time_interval)
    if @values['success'] > 0.9 && @values['confidence'] > 0.92
      if (Time.now - @last_action) > time_interval
        @last_action = Time.now
        if @values['AU01_r'] > 2.1
          puts action_units[:AU01]
          xdo_key('Page_Down')
        elsif @values['AU09_r'] > 2
          puts action_units[:AU09]
          xdo_key('Page_Up')
        end
      end
    end
  end

  # presense (0 absent, 1 present)
  def action_by_presence(time_interval)
    if @values['success'] > 0.9 && @values['confidence'] > 0.92
      if (Time.now - @last_action) > time_interval
        @last_action = Time.now
        if first_on('AU45_c') && on('AU09_c')
          puts "#{action_units[:AU45]} and #{action_units[:AU09]}"
          xdo_key('Page_Down')
        elsif first_on('AU45_c') && on('AU14_c')
          puts "#{action_units[:AU45]} and #{action_units[:AU14]}"
          xdo_key('Page_Up')
        end
      end
    end
    @previous_values = @values
  end

  def action_units
    { AU01: 'Inner brow raiser',
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
      AU45: 'Blink' }
  end
end
