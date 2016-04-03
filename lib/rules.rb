module OneManBand
  class Rule
    attr_reader :name, :options, :block

    def initialize name, rule, options={}, &block
      @name, @rule, @options, @block = name, rule, options, block
    end

    def active?
      @options.size != 0 || @block
    end

    def resolved_rule_str rules
      @resolved_rule_str ||= rule_str.gsub(/<(.+?)>/) do 
        "(#{rules[$1].resolved_rule_str(rules)})" 
      end
    end

    def to_jsgf
      "<#{@name}> = #{rule_str.gsub(/(<.+?>)\?/, '(\1|<NULL>)')};"
    end

    def rule_str
      if @rule.is_a? String
        @rule
      else
        @rule.join('|')
      end
    end

    def regex_str rules
      resolved_rule_str(rules).gsub(/\((.+?)\)\?/,'((\1) )?')
    end
  end

  class Rules
    attr_reader :rules

    def initialize &block
      @rules = {}
      instance_eval &block
    end

    def rule name, rule, options={}, &block
      @rules[name] = Rule.new(name, rule, options, &block)
    end

    def to_jsgf
      rules = @rules.values.map(&:to_jsgf).join("\n")
# as far as I can tell, pocketsphinx only lets us select a single public rule, so instead we generate our own public rule that includes all the active rules
      active = @rules.values.select { |r| r.active? }.map { |r| "<#{r.name}>" }.join('|')
      rule_to_rule_them_all = "public <rule_to_rule_them_all> = #{active};"
      "#JSGF V1.0;\n\ngrammar default;\n\n#{rules}\n#{rule_to_rule_them_all}"
    end

    def regexes
      @regexes ||= {}.tap do |result|
        @rules.values.select { |r| r.active? }.each do |rule|
          result[/#{rule.regex_str(@rules)}/] = rule
        end
      end
    end
  end
end
