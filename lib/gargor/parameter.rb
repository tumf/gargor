# -*- coding: utf-8 -*-
class Gargor
  class Parameter
    attr_accessor :file, :path, :value, :name
    alias :json_file :file=
    alias :json_path :path=
    alias :mutation :value=
    alias_method :eql, :==
    def initialize name
      @name = name
    end

    def to_s
      @value.to_s
    end

    def ==(other)
      name == other.name and
        file == other.file and
        path == other.path and
        value == other.value
    end

  end
end
