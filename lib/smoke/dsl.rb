class Smoke
  class DSL
    
    class Definition
      Harness = Smoke::Test::Harness
      
      def initialize(name, dsl)
        @name = name.to_sym
        @dsl = dsl
        @steps = []
        @requirements = []
        Harness.public_instance_methods(true).each do |m|
          define_singleton_method(m) {|*args, &block| _handle_method(m, *args, &block) }
        end
      end

      attr_reader :name, :steps, :requirements
      
      # def requirements
      #   @_requirements ||= @requirements | @requirements.flat_map{|r| @dsl.definitions[r].requirements }
      # end
      
      def require(*definitions)
        @requirements += Array(definitions).flatten.map(&:to_sym)
      end

      def sleep(*s)
        STDERR.puts "WARNING: Use 'delay', not 'sleep' in your test definitions."
        delay(*s)
      end

      def harness ; self.class::Harness ; end
      
      def mode ; :standard ; end

      def method_missing(name, *args, &block)
        _handle_method(name, *args, &block)
      end
      
      def _handle_method(name, *args, &block)
        raise NotImplementedError, "No blocks in step definitions please!" unless block.nil?
        steps << [name, *args]
      end
      
    end
    
    # class JsonDefinition < Definition
    #   Harness = Smoke::Test::JsonHarness
    #
    #   def initialize(name, dsl, block)
    #     super(name, dsl)
    #     @block = block
    #   end
    #
    #   def mode ; :json ; end
    #   def _handle_method(name, *args, &block)
    #     STDERR.puts [name, args, block].inspect
    #     steps << (block ? [name, *args, block] : [name, *args])
    #   end
    # end
    
    class Proxy
      
      def initialize(body, file, dsl)
        @file = file
        @dsl = dsl
        @body = body.gsub(/\{\{([^\}]+)\}\}/){ eval($1, nil, file) }
      end
      
      def evaluate
        instance_eval(@body, @file)
      end
      
      def smoke(name, *a, &block)
        definition = Definition.new(name, @dsl)
        definition.instance_eval(&block)
        @dsl.definitions[name] = definition
      end
      
      def jsmoke(name, *a, &block)
        # definition = JsonDefinition.new(name, @dsl, block)
        # @dsl.definitions[name] = definition
      end

      def respond_to_missing?(name, all = false)
        super || @dsl.smoke.configuration.respond_to?(name)
      end
      
      def method_missing(name, *args, &block)
        if @dsl.smoke.configuration.respond_to?(name)
          @dsl.smoke.configuration.send(name, *args)
        else
          raise NotImplementedError, "I don't know how to #{name}!"
        end
      end
      
    end
    
    attr_reader :smoke
    def initialize(smoke)
      @smoke = smoke
    end
    
    def load(file)
      Proxy.new(IO.read(file), file, self).evaluate
    end
  
    def load_all(dir = nil)
      dir ||= File.join(File.dirname(__dir__), 'tests' )
      Dir[File.join(dir, '**', '*.smoke')].each{|f| load(f) }
    end
    
    def definitions ; @definitions ||= {} ; end
    
    def definitions!(dir = nil)
      load_all(dir) if @definitions.nil?
      definitions
    end
    
  end
end
