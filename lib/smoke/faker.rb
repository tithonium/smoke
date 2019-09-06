require 'faker'

class Smoke
  module Faker
    class << self
      {
        "Name" => %w[first_name middle_name last_name name_with_middle],
        "Company" => {
          company_name: :name,
        },
        "Internet" => {
          email: :safe_email,
        },
        "Lorem" => %w[word words sentence paragraph question],
        "Number" => %w[number decimal],
        "PhoneNumber" => %w[phone_number cell_phone]
      }.each do |faker_module, methods|
        faker_module = ::Faker.const_get(faker_module)
        methods.each do |our_name, faker_name|
          faker_name ||= our_name
          define_method(our_name) { faker_module.send(faker_name) }
        end
      end
      
      def method_missing(method, *)
        if m = method.match(/\A(character|word)s_(\d+)\Z/)
          return ::Faker::Lorem.send("#{m[1]}s", number: m[2].to_i)
        elsif m = method.match(/\Aemail_(\d+)\Z/)
          return ::Faker::Internet.safe_email(name: m[1].to_i)
        elsif m = method.match(/\Adecimal_([0-9_]+)\Z/)
          ld, rd = m[1].split('_').map(&:to_i)
          rd ||= 2
          return ::Faker::Number.decimal(l_digits: ld, r_digits: rd)
        end
        super
      end
      
      def respond_to_missing?(method, _)
        return true if method.match(/\A((character|word|)s|email|decimal)_(\d+)\Z/)
        super
      end
      
    end
  end
end
