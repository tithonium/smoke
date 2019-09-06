require 'capybara'

# We use div.btn's for some of our buttons, so we'll just redefine this here for now...
module XPath
  module HTML
    def button(locator)
      locator = locator.to_s
      button = descendant(:input)[attr(:type).one_of('submit', 'reset', 'image', 'button')][attr(:id).equals(locator) | attr(:value).is(locator) | attr(:title).is(locator)]
      button += descendant(:button)[attr(:id).equals(locator) | attr(:value).is(locator) | string.n.is(locator) | attr(:title).is(locator)]
      button += descendant(:input)[attr(:type).equals('image')][attr(:alt).is(locator)]
      button += descendant(:div)[attr(:class).is('btn')][attr(:id).equals(locator) | string.n.is(locator) | attr(:title).is(locator)]
    end
  end
end

class Object
  def eigenclass
    class << self
      self
    end
  end
end
