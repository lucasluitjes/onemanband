require 'pocketsphinx-ruby'
require '../lib/rules'
require '../lib/base_controller'

include OneManBand

rules = Rules.new do 
  nums = %w{one two three four five six seven eight nine ten}
  rule 'number', nums
  rule 'direction', %w{left right up down}
  rule 'optional_number', '<number>?'
  rule 'move_mouse', '<optional_number>mouse <direction>', action: :nop
  rule 'open_tag', 'open tag <number>', action: :nop
end

class Controller < BaseController
  def initialize *args
    @log_file = File.open('log', 'a')
    @log_file.sync = true
    super *args
  end

  def before_action raw, matches, path_score
    @log_file.puts "#{path_score}: #{raw}"
  end

  def stop
    @log_file.close
  end

  def action_nop *args
    # Do nothing- mostly for debugging
  end
end

controller = Controller.new(rules)

at_exit { controller.stop }

controller.start
