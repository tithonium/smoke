# Smoke

Smoke is a quick-and-dirty capybara-based smoke testing tool. A simple DSL allows you to define tests that run in a browser against your website and check that specific text and css selectors exist in the result.

## Installation

You'll need to install `phantomjs`, using whatever package management process is appropriate for your environment.

Add this line to your application's Gemfile:

```ruby
gem 'smoke'
```

If you want to use the chrome browser to run the tests instead, install `chromedriver` and add `selenium-webdriver` to your Gemfile.


And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smoke

## Usage

1. Create test files in your project's `smoke`, `test/smoke`, or `spec/smoke` directories. Use the `.smoke` extension.
2. Run `bundle exec smoke run`

## DSL

TODO: I need to document the DSL

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tithonium/smoke.
