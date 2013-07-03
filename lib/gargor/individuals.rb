class Gargor
  class Individuals < Array
    def has? i
      !!self.find { |ii| ii.params == i.params }
    end
  end
end
