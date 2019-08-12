class Smoke
  class Error < StandardError ; end
  class PermissionsError < Error ; def initialize(msg='Did you set an appropriate user?') ; super ; end ; end
end
