require 'colorize'

class Smoke
  class Test
    module Harness
      
      def session
        @smoke.session
      end
      
      def reset_session
        @smoke.reset_session
      end
      
      def browser
        @smoke.browser
      end

      def echo(*a)
        puts *a
      end
      
      def visit(url)
        puts "Navigating to #{url.inspect}...".light_black
        session.visit(url)
        wait_until_loaded
      end
      
      def go_back
        session.driver.go_back
      end
      
      def inspector!
        session.driver.debug
      end
      
      def show_page
        return unless RUBY_PLATFORM =~ /darwin/i
        fn = "#{ENV['HOME']}/screenshot.png"
        session.driver.save_screenshot(fn)
        system "open '#{fn}'"
        sleep 0.5
        File.unlink(fn)
      end
      
      def click(locator, options = {})
        options[:match] ||= :first
        puts "Clicking on #{locator.inspect}...".light_black
        _possibly_within(options) do
          session.click_link_or_button(locator, options)
        end
        wait_until_loaded
      end

      def click_element(locator, options = {})
        options[:match] ||= :first
        puts "Clicking on #{locator.inspect}...".light_black
        _possibly_within(options) do
          session.find(locator, options).click
        end
        # wait_until_loaded
      end
      
      def check(locator, options = {})
        puts "Checking #{locator.inspect}...".light_black
        _possibly_within(options) do
          session.check(locator, options)
        end
      end
      
      def uncheck(locator, options = {})
        puts "Unchecking #{locator.inspect}...".light_black
        _possibly_within(options) do
          session.uncheck(locator, options)
        end
      end
      
      def fill(field_name, value, options = {})
        
        if value.is_a?(Symbol) && Smoke::Faker.respond_to?(value)
          value = Smoke::Faker.send(value)
        end
        
        _possibly_within(options) do
          session.fill_in(field_name, with: value)
        end
      end
      
      # hover 'Tools' => hover 'li', text: 'Tools'
      def hover(*element)
        if element.length == 1 && element[0] !~ /\A(li|div|button|a|span)\Z/
          element = ['li', text: element[0]]
        end
        puts "Hovering over #{element[1][:text].inspect}...".light_black rescue nil
        session.find(*Array(element)).hover
      end
      
      def string(len = 10)
        SecureRandom.hex(len)
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
      
      def wait
        STDERR.print "Press enter..."
        STDIN.gets
      end
      
      def screenshot
        @screenshot_date ||= Time.now.strftime('%y.%m.%d.%H%M')
        @screenshot_count ||= 0
        @screenshot_count += 1
        filename = "screenshot-%s-%3.3d.png" % [@screenshot_date, @screenshot_count]
        session.save_screenshot(filename)
        filename
      end
      
      def fake_screenshot
        File.unlink(screenshot)
      end
      
      def wait_until_loaded
        started_waiting = Time.now
        while session.has_selector?('.throbber,img[src*="throbber"]')
          sleep 0.5
        end
        if (wait_time = Time.now - started_waiting) > 2.25
          puts "Waited %.1f seconds for %s to load".yellow % [wait_time, session.current_url.sub(%r[.+://[^/]+],'')]
        end
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
      
      def _possibly_within(options, &block)
        if options.key?(:within_frame)
          within = Array(options.delete(:within_frame)).map {|a| a == :recaptcha ? recaptcha_frame : a }
          session.within_frame(*within) { _possibly_within(options, &block) }
        elsif options.key?(:within)
          within = Array(options.delete(:within))
          session.within(*within) { _possibly_within(options, &block) }
        else
          block.call
        end
      end
      
    end
  end
end
