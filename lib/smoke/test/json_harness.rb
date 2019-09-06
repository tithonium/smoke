require 'colorize'

class Smoke
  class Test
    module JsonHarness
      
      def session
        @smoke.session
      end
      
      def reset_session
        @smoke.reset_session
      end
      
      def browser
        @smoke.browser
      end

      def body
        @body ||= session.body
      end
      
      def json
        @json ||= begin
          js = body.sub(/\A(<[^>]+>)+/, '').sub(/(<[^>]+>)+\Z/, '')
          JSON.load(js)
        end
      end
      
      def display(*a)
        a = a.map {|v| v.is_a?(Proc) ? v.call : v}
        puts (a.length == 1 ? a.first : a).inspect
      end
      
      def echo(*a)
        puts *a
      end
      
      def remember(key, val = nil)
        @memory ||= {}
        if val
          STDERR.puts self.inspect
          val = eval "val.call" if val.is_a?(Proc)
          @memory[:key] = val
        end
        STDERR.puts [key, val].inspect
        @memory[:key]
      end
      
      def visit(url)
        puts "Navigating to #{url.inspect}...".light_black
        session.visit(url)
      end
      
      def go_back(block)
        session.driver.go_back
      end
      
      def inspector!
        session.driver.debug
      end
      
      def delay(s = 2)
        while s > 5
          str = "Waiting #{s}s..."
          STDERR.print str.light_magenta
          sleep 5
          STDERR.print "\b \b" * str.length
          s -= 5
        end
        sleep s
      end
      
      def wait(block)
        STDERR.print "Press enter..."
        STDIN.gets
      end
      
      def _expect(checks, term = "expectation", fail_color = :red, pass_color = :green)
        checks.each do |type, values|
          Array(values).each do |value|
            pass = case type
            when :url
              value === session.current_url
            when :selector, :css
              session.has_selector?(value)
            when :no_selector, :no_css
              !session.has_selector?(value)
            when :content, :text
              session.has_content?(value)
            when :no_content, :no_text
              !session.has_content?(value)
            when :cookie
              case value
              when Array
                value.last === session.driver.cookies[value.first.to_s]&.value
              else
                session.driver.cookies.values.any?{|v| value === v.value }
              end
            else
              raise NotImplementedError, "Bad check type: #{type}"
            end
            unless pass
              type_desc = type == :url ? "#{type} (#{session.current_url.inspect})" : type
              puts "Failed #{term}:  #{type_desc} === #{value.inspect}".send(fail_color)
              self.errors += 1
            else
              puts "Passed #{term}:  #{type} === #{value.inspect}".send(pass_color)
              self.passes += 1
            end
          end
        end
      end
      
      def expect(checks)
        _possibly_within(checks) { _expect(checks, "expectation") }
      end
      
      def desire(checks)
        p, e = self.passes, self.errors
        begin
          _expect(checks, "desire", :yellow)
        rescue Exception => ex
          puts "Ignoring exception - #{ex.class.name}: #{ex.message}".yellow
        end
        self.passes, self.errors = p, e
      end
      
      def show_cookie(name = nil)
        if name
          puts "#{name}: #{session.driver.cookies[name.to_s]&.value.inspect}"
        else
          puts "Cookies: #{session.driver.cookies.each_with_object({}){|(k,v),h| h[k]=v.value}.inspect}"
        end
      end
      alias :show_cookies :show_cookie
      
      def ruby(block)
        eval block
      rescue => ex
        STDERR.puts "#{ex.class.name}: #{ex.message}"
        STDERR.puts ex.backtrace.join("\n")
      end

      def click_recaptcha
        session.within_frame(recaptcha_frame) { session.find('.rc-anchor').click }
      end

      private

      def recaptcha_frame
        session.all('iframe').find{|f| f['src'].include?('recaptcha') }
      end
      
      def _possibly_within(options)
        if options.key?(:within_frame)
          within = Array(options.delete(:within_frame)).map {|a| a == :recaptcha ? recaptcha_frame : a }
          session.within_frame(*within) { _possibly_within(options) }
        elsif options.key?(:within)
          within = Array(options.delete(:within))
          session.within(*within) { _possibly_within(options) }
        else
          block.call
        end
      end
      
    end
  end
end
