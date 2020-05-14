require"pp"
require"open3"
require 'file-tail'
Thread.new{`./build/bin/FeatureExtraction -device 0 -aus -2Dfp -3Dfp -pdmparams -pose -gaze -of output.csv`}
sleep 5
headers = File.read("processed/output.csv").split("\n").first.split(",").map(&:strip)
pp headers
STDOUT.sync = true
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
output_headers = headers.select do |n| 
  n.include?("AU") ||
  %w{confidence success}.include?(n)
end.map {|n| headers.index(n)}
counter = 0
last_action = Time.now
@previous_values = {}
overview = []
#at_exit {pp overview}
#Thread.new{sleep 10;exit 1}
Open3.popen3("tail -f processed/output.csv") do |stdin, stdout, stderr, wait_thr|
#  while line = stdout.read
  stdout.each_line do |line|
  puts 'line'
    @values = {}
    line.split(",").map(&:to_f).each_with_index{|n,i| @values[headers[i]] = n}
    puts'2'
    puts @values["confidence"]
    next unless @values["success"] > 0.9
    next unless @values["confidence"] > 0.92
    puts'3'
    #pp [@values["confidence"],@values["AU01_c"],@values["AU12_c"]]
    #overview << [@values["confidence"],@values["AU01_c"],@values["AU12_c"]]
    if (Time.now-last_action)>0.8
      puts'4'
      last_action = Time.now
      if @values["AU01_r"] > 2.1#first_on("AU45_c") && on("AU09_c")
        puts'5'
        xdo_key("Page_Down") 
        puts'6'
      elsif @values["AU09_r"] > 2#first_on("AU45_c") && on("AU14_c")
      puts'7'
        xdo_key("Page_Up") 
        puts'8'
      end
    end
puts'9'
    @previous_values = @values
    puts'10'
#next
# debug output
    next unless (counter += 1) % 8 == 0
    puts "\n\n"
    puts'11'
    output_headers.each {|n| puts "#{headers[n]}: #{@values[headers[n]]}"}
    puts'12'
  end
end