# frozen_string_literal: true

def stop
  puts 'Stopping...'
end

def update
  puts 'Updating...'
end

def start
  puts 'Starting...'
  _run
end

def _run
  sleep 2
  Process.kill('USR1', @pid)
  sleep 2
  puts 'end _run'
end

@pid = fork do
  Signal.trap('USR1') do
    stop
    update
    start
  end

  start
end
