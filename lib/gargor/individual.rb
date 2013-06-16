# -*- coding: utf-8 -*-
require 'json'
require 'jsonpath'
require 'benchmark'

class Gargor
  class Individual
    attr_accessor :params,:fitness
    def initialize
      @params = {}
      @fitness = nil
    end

    def to_s
      [@params,@fitness].to_s
    end

    def load_now
      @params.each { |name,param|
        json = File.open(param.file).read
        @params[name].value = JsonPath.on(json,param.path).first
      }
      self
    end

    def set_params
      puts "==> set params"
      puts @params
      @params.each { |name,param|
        json = File.open(param.file).read
        json = JSON.pretty_generate(JsonPath.for(json).gsub(param.path) { |v| param.value }.to_hash)
        # 書き出し
        File.open(param.file,"w") { |f| f.write(json) }
        puts "    write #{param.file}"
      }
    end

    def deploy
      ret = true
      Gargor.opt("target_nodes").each { |node|
        puts "==> deploy to #{node}"
        cmd = Gargor.opt("target_cooking_cmd") % [node]
        puts "    #{cmd}"
        r = system(cmd)
        unless r
          puts "deploy failed"
          @fitness = 0
          sleep 1
        end
        ret &= r
      }
      ret
    end


    def attack
      ret = nil;out = nil
      cmd = Gargor.opt('attack_cmd')
      puts "==> attack"
      puts "execute: #{cmd}"
      tms = Benchmark.realtime do
        out = `#{cmd}`
        ret = $?
      end

      @fitness = Gargor.opt('evaluate_proc').call(ret.to_i,out,tms)
      puts "fitness: #{@fitness}"
      @fitness
    end
  end
end
