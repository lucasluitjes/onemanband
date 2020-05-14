def xdo_key key
  `DISPLAY=':0.0' xdotool key #{key}`
  "xdotool key #{key}"
end
def first_on key
  @values[key] == 1.0 && @previous_values[key] == 0.0
end
def on key
  @values[key] == 1.0
end
