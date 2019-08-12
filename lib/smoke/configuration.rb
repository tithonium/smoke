class Smoke
  class Configuration
    
    def initialize(smoke, argv = [])
      @smoke = smoke
      
      @options = {
        driver: :poltergeist,
        js_errors: true,
        app_root: `git rev-parse --show-toplevel`.chomp,
      }

      idx = 0
      while idx < argv.size
        if case arg = argv[idx]
          when /\A--slow\Z/
            @options[:slow] = true
          when /\A--force\Z/
            @options[:force] = true
          when /\A--trace\Z/
            @options[:trace] = true
          when /\A--(?:ignore|no)-j(?:ava)?s(?:cript)?(?:-errors)?\Z/
            @options[:js_errors] = false
          when /\A--(?:dry[_-]?run|no-?op)\Z/
            @options[:dry_run] = true
          when /\A--host/
            if arg =~ /\A--host=(.+)/
              @host = $1
            else
              @host = argv.delete_at(idx + 1)
            end
            if @host.nil? || @host == "" || @host =~ /\A-/
              puts "Bad 'host' parameter: #{@host.inspect}"
              exit!(1)
            end
            true
          when /\A--config?/
            if arg =~ /\A--config=(.+)/
              @options[:config_file] = $1
            else
              @options[:config_file] = argv.delete_at(idx + 1)
            end
          when /\A--root?/
            if arg =~ /\A--root=(.+)/
              @options[:test_root] = $1
            else
              @options[:test_root] = argv.delete_at(idx + 1)
            end
          when /\A--driver/
            if arg =~ /\A--driver=(.+)/
              @options[:driver] = $1.to_sym
            else
              @options[:driver] = argv.delete_at(idx + 1).to_sym
            end
            unless [:poltergeist, :chrome].include?(@options[:driver])
              puts "Bad 'driver' parameter: #{@options[:driver].inspect}"
              exit!(1)
            end
            true
          end
          argv.delete_at(idx)
        else
          idx += 1
        end
      end

      unless @options[:config_file]
        %w[config/smoke.yml config/smoke.yaml smoke.yml smoke.yaml].each do |file|
          filename = [@options[:app_root], file].join('/')
          if File.exist?(filename)
            @options[:config_file] = filename
            break
          end
        end
      end
            
      if @options[:config_file] && File.exist?(@options[:config_file])
        config = YAML.load(IO.read(@options[:config_file]))
        @options = config.merge(@options)
      end

      unless @options[:test_root]
        %w[smoke test/smoke spec/smoke].each do |file|
          dirname = [@options[:app_root], file].join('/')
          if File.exist?(dirname)
            @options[:test_root] = dirname
            break
          end
        end
      end
    end
    
    def host
      @host ||= @options[:host] || ENV['SMOKE_HOST'] || "localhost:3000"
    end
    
    def https
      @https ||= (@options[:https] || (if ENV.key?('SMOKE_HTTPS')
        ENV['SMOKE_HTTPS'] =~ /1|y(es)?|t(rue)?/i
      else
        host !~ /localhost/
      end)) ? 'https' : 'http'
    end

    %i[driver test_root].each do |opt|
      define_method(opt) { @options[opt] }
    end
    
    %i[js_errors slow trace force dry_run].each do |opt|
      define_method("#{opt}?") { !!@options[opt] }
    end
    
  end
end
