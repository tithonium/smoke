# require_relative 'test/harness'

class Smoke
  class Test
    include Comparable
    include Smoke::Test::Harness
    
    def self.new_from_list(definitions, smoke)
      definitions.map{|d| new(d, smoke) }
    end
    
    attr_reader :name, :steps, :exception, :has_run
    attr_accessor :errors, :passes
    
    def initialize(definition, smoke)
      @smoke = smoke
      @name = definition.name.to_sym
      @requirements = definition.requirements.freeze
      @steps = definition.steps.freeze
      @passes = 0
      @errors = 0
      @exception = nil
      @has_run = false
    end
    
    def requirements
      @_requirements ||= @requirements | @requirements.flat_map{|r| @smoke.dsl.definitions[r].requirements }
    end
    
    def <=>(other)
      raise TypeError, "Can't compare #{self.class} with #{other.class}" unless other.is_a?(Smoke::Test)
      
      if self.requirements.include?(other.name)
        1
      elsif other.requirements.include?(self.name)
        -1
      else
        self.name <=> other.name
      end
    end
    
    def inspect
      # %Q[#<#{self.class.name}:#{object_id} #{name} #{steps.map(&:first).inspect}>]
      %Q[#<#{self.class.name} #{name}>]
    end
    
    def failed?
      @errors > 0 || @exception
    end
    
    def has_run?
      !!@has_run
    end
    
    def ensure_prerequisites
      requirements.each do |required_test_name|
        required_test = @smoke.tests_by_name[required_test_name]
        required_test.run
      end
    end
    
    def run
      return if has_run?
      @has_run = true
      ensure_prerequisites
      
      if @smoke.configuration.dry_run?
        puts name
        return
      end
      
      puts "#{name}:"
      steps.each do |step|
        if respond_to?(step.first)
          send(*step)
        elsif session.respond_to?(step.first)
          session.send(*step)
        else
          raise NotImplementedError, "Unsupported step definition: #{step.inspect}"
        end
      end
      
    rescue => ex
      STDERR.puts "#{ex.class.name}: #{ex.message}".red
      @exception = ex
      # unless ex.is_a?(Smoke::Error) || ex.is_a?(Capybara::Poltergeist::JavascriptError)
        puts ex.backtrace.join("\n") if @smoke.configuration.trace?
        unless @smoke.configuration.force?
          sleep 4
          raise ex
        end
      # end
    ensure
      puts
    end
    
  end
end
