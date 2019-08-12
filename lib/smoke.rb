Dir.glob(File.join(__dir__, 'smoke', '**', '*.rb'), &method(:require))

require 'capybara'

class Smoke
  
  def initialize(argv)
    @argv = argv
    configuration
  end
  
  def console(context = binding)
    require 'pry'
    Pry.start(context, quiet: true)
  end
  
  def configuration
    @configuration ||= Smoke::Configuration.new(self, @argv)
  end
  
  def dsl
    @dsl ||= Smoke::DSL.new(self)
  end
  
  def tests
    @tests ||= Smoke::Test.new_from_list(dsl.definitions!(configuration.test_root).values, self).sort
  end
  
  def tests_by_name
    @tests_by_name ||= tests.each_with_object({}){|t,h| h[t.name] = t }
  end
  
  def run_all(filters = [])
    tests_to_run = if filters.size > 0
      filter_re = %r[(?:#{filters.join('|')})]i
      tests.select{|t| t.name =~ filter_re }
    else
      tests
    end
    if tests_to_run.size == 0
      STDERR.puts "No tests to run!".light_red
    else
      tests_to_run.each(&:run)
    end
  rescue => ex
    STDERR.puts "Aborting due to exception".red
  end
  
  def failed?
    tests.any?(&:failed?)
  end
  
  def report
    if failed?
      print " FAILURE  ".light_red
    else
      print " SUCCESS  ".light_green
    end
    print "  👍 :%d  ".green % tests.map(&:passes).inject(0, &:+)
    print "  👎 :%d  ".red % tests.map(&:errors).inject(0, &:+)
    puts  "  💥 :%d  ".red % tests.select(&:exception).size
    puts
  end
  
  def session
    unless @session
      configure_capybara
      @session = Capybara::Session.new(configuration.driver)
      resize
      Signal.trap('INT') { browser.quit }
    end
    @session
  end
  def reset_session
    old_session = @session
    Thread.new do
      old_session.driver.browser.quit rescue nil
      old_session.reset! rescue nil
    end
    @session = nil
    session
  end
  
  def driver
    session.driver
  end
  
  def browser
    driver.browser
  end
  
  def resize(w = 1280, h = 1024)
    if browser.respond_to?(:manage)
      browser.manage.window.resize_to(w, h)
    elsif driver.respond_to?(:resize)
      driver.resize(w, h)
    end
  end
  
  # def cookies(domain=nil)
  #   cookies = browser.manage.all_cookies
  #   cookies = cookies.select{|c| c[:domain] =~ domain} if domain
  #   cookies
  # end
  
  private
  
  def configure_capybara
    return if @capybara_configured
    @capybara_configured = true
    
    if configuration.driver == :poltergeist
      require 'capybara/poltergeist'
      Capybara.register_driver(:poltergeist) { |app| Capybara::Poltergeist::Driver.new(app, timeout: 120, js_errors: configuration.js_errors?, inspector: true) }
      Capybara.default_driver = Capybara.javascript_driver = :poltergeist
    elsif configuration.driver == :chrome
      require 'selenium-webdriver'
      Capybara.register_driver(:chrome) { |app| Capybara::Selenium::Driver.new(app, :browser => :chrome) }
      Capybara.default_driver = Capybara.javascript_driver = :chrome
    else
      raise "Bad driver specified"
    end
  end
  
end
