class BaseController
  def initialize rules
    @rules = rules
    initialize_pocketsphinx
  end

  def initialize_pocketsphinx 
    # pocketsphinx-ruby currently only allows grammars to be loaded from file (until this gets merged: https://github.com/maweil/pocketsphinx-ruby/tree/seperate_jsgf_initializers), so for now we write it in a file and then load it
    # TODO: use a tmp file like a civilized person
    raise 'jsgf file already exists' if File.exist?('jsgf')
    File.open('jsgf', 'w') { |f| f.write @rules.to_jsgf }
    configuration = Pocketsphinx::Configuration::Grammar.new('jsgf')
    `rm jsgf`

    @pocketsphinx_recognizer = Pocketsphinx::LiveSpeechRecognizer.new(configuration)
  end

  def get_rule speech
    @rules.regexes.each do |regex, rule|
      return rule if speech =~ regex
    end
    raise "rule not found for: #{speech}"
  end

  def start
    @pocketsphinx_recognizer.recognize do |speech|
      rule = get_rule(speech)

      matches = speech.scan(/#{rule.regex_str(@rules.rules)}/)

      before_action speech, matches, speech.path_score
      if rule.options[:action]
        send(:"action_#{rule.options[:action]}", speech, matches, speech.path_score) 
      else
        instance_eval speech, matches, speech.path_score, &rule.block 
      end
    end
  end

  def before_action *args
  end
end
