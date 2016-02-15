require 'json'
class Gargor
  class Individuals < Array
    def has?(i)
      !!find { |ii| ii.params == i.params }
    end

    def to_json
      collect(&:to_hash).to_json
    end
  end
end
