class Choice
  def initialize controller
    @controller = controller
    @actions = [:root,[
      [:entr,'find | entr ruby '],
      [:return,Proc.new{@controller.xdo_key('Return')}],
      [:test,:test],
      [:cd,[
        [:cd, 'cd '],
        [:infrastructure, 'cd ~/code/infrastructure'],
      ]]
    ]]
    @current_path = []
  end

  def choose value
    pp current_action
    if current_action.last.is_a?(Array)
      @current_path << value - 1
      return display_choices if current_action.last.is_a?(Array)
    end
    if current_action.last.is_a?(Symbol)
      send current_action.last
      return
    elsif current_action.last.is_a?(String)
      @controller.xdo_type current_action.last
    elsif current_action.last.is_a?(Proc)
      instance_eval &current_action.last
    end
    @current_path = []
    display_choices
  end

  def current_action 
    tmp = @actions
    @current_path.each do |i|
      tmp = tmp.last[i]
      break unless tmp
    end
    tmp
  end

  def display_choices str=nil
    File.open('choices','w') do |f|
      f.puts str if str
      current_action.last.each_with_index do |n,i|
        f.puts "#{i+1}) #{n.first.to_s}"
      end
    end
  end

  def test
    @controller.xdo_type 'test'
    @current_path = []
  end


    
end

class Controller
  attr_reader :last_input, :blacklist

  BANKS = %w{wmii vim thunderbird misc nil nil nil nil nil choice}
  DIRECTIONS = [nil, 'left', 'down', 'right', nil, nil, 'up']

  def initialize
    @last_input = Time.now.to_f
    #@blacklist = ['w', (0..9).map(&:to_s), 'number mode on', 'b', 'k', 'j', 'Up', 'Down', 'Page_Down', 'Page_Up'].flatten.map {|n| "xdotool key #{n}"}
    @blacklist = ['w', 'number mode on', 'b', 'k', 'j', 'Up', 'Down', 'Page_Down', 'Page_Up'].flatten.map {|n| "xdotool key #{n}"}
    @choice = Choice.new(self)
  end

  def process bank_index, value
    bank = BANKS[bank_index]
    puts "bank #{bank || bank_index}, value #{value}"
    begin
      result = send(:"#{bank}_bank", value) || 'command not found'
      @last_input = Time.now.to_f unless blacklist.include?(result)
      puts result
    rescue => e
      puts e.inspect
      puts e.backtrace.join("\n")
    end
  end

  def choice_bank value
    @choice.choose value
  end

  WMII_TAGS = [nil, nil,nil,nil,1,2,nil,3, 4,5]

  def wmii_bank value
    if direction = DIRECTIONS[value]
      wmiir "/tag/sel/ctl select #{direction}"
    elsif tag = WMII_TAGS[value]
      wmiir("/ctl view \"#{tag}\"")
    else
      @wmii_toggle ||= false
      @wmii_toggle = !@wmii_toggle
      if @wmii_toggle
        wmiir('/tag/sel/ctl colmode sel default-max')
      else
        wmiir('/tag/sel/ctl colmode sel stack-max')
      end
    end
  end

  CHROMIUM_KEYS = [nil, nil, 'Return', 'Right', 'Down', 'Page_Down', 'Tab', 'Escape', 'H', 'Up', 'Page_Up']
  def chromium_bank value
    if @ascii_buffer
      @ascii_buffer << (value == 10 ? 0 : value)
      
      if @ascii_buffer.size == 2
        index = @ascii_buffer.map(&:to_s).join.to_i
        if @first_key_pressed
          @ascii_buffer = nil
        else
          @ascii_buffer = []
          @first_key_pressed = true
        end
        puts index

        character = ('a'..'z').to_a[index % 30]
        character.upcase! if index > 29
        xdo_key character unless index == 99
      else
        "#{@ascii_buffer.last} added to buffer"
      end
    else
      if value == 1
        xdo_key 'F' 
        @ascii_buffer = []
        @first_key_pressed = false
        'created buffer'
      else key = CHROMIUM_KEYS[value]
        xdo_key key
      end
    end
  end

  THUNDERBIRD_KEYS = [
    nil, 
    'Return',
    'Menu+m+r',
    'Control_L+F6',
    'Down',
    'Page_Down',
    'Control_L+Shift_L+Tab', 
    'Control_L+Tab', 
    'Control_L+F4',
    'Up',
    'Page_Up'
  ]
  def thunderbird_bank value
    xdo_key THUNDERBIRD_KEYS[value]
  end

  MISC_KEYS = [ 
    nil,
    'Left',
    'j',
    'Right',
    'w',
    'Page_Down',
    'k',
    'b',
    'Return',
    nil,
    'Page_Up'
  ]
  def misc_bank value
    if MISC_KEYS[value] == 'b'
      xdo_type 'dd'
    else
      xdo_key MISC_KEYS[value]
    end
  end

  VIM_KEYS = [
    nil,
    'Control_L+h',
    'j',
    'Control_L+l',
    'w',
    'Page_Down',
    'k',
    'b',
    'Return',
    nil,
    'Page_Up'
  ]
  def vim_bank value
    if @number
      @number = false
      xdo_key value.to_s
    else
      if key = VIM_KEYS[value]
        xdo_key key
      #elsif [4, 7].include? value
      #  xdo_type(value == 4 ? ':vnew .' : ':q')
      #  xdo_key 'Return'
      else
        @number = true
        'number mode on'
      end
    end
  end

  def _bank value
    'bank not found'
  end

  def wmiir str
    `DISPLAY=':0.0' wmiir xwrite #{str}`
    "wmiir xwrite #{str}"
  end

  def xdo_key key
    `DISPLAY=':0.0' xdotool key #{key}`
    "xdotool key #{key}"
  end
  
  def xdo_type str
    `DISPLAY=':0.0' xdotool type '#{str}'`
    "xdotool type '#{str}'"
  end

  def xdotool str
    `DISPLAY=':0.0' xdotool #{str}`
    "xdotool #{str}"
  end
end
