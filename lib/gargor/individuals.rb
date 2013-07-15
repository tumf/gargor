require 'json'
class Gargor
  class Individuals < Array
    def has? i
      !!self.find { |ii| ii.params == i.params }
    end
    def to_json
      collect { |i| i.to_hash }.to_json
    end
  end
end
