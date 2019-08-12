class Smoke
  class DSL
    
    class Definition
      def initialize(name, dsl)
        @name = name.to_sym
        @dsl = dsl
        @steps = []
        @requirements = []
      end

      attr_reader :name, :steps, :requirements
      
      # def requirements
      #   @_requirements ||= @requirements | @requirements.flat_map{|r| @dsl.definitions[r].requirements }
      # end
      
      def require(*definitions)
        @requirements += Array(definitions).flatten.map(&:to_sym)
      end

      def method_missing(name, *args, &block)
        raise NotImplementedError, "No blocks in step definitions please!" unless block.nil?
        if @dsl.smoke.configuration.respond_to?(name)
          @dsl.smoke.configuration.send(name, *args)
        else
          steps << [name, *args]
        end
      end
      
    end
    
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
