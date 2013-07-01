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

    def log message,level = :debug
      Gargor.log message,level
    end

    def load_now
      log "==> load current json"
      @params.each { |name,param|
        json = File.open(param.file).read
        @params[name].value = JsonPath.on(json,param.path).first
      }
      self
    end

    def set_params
      log "==> set params"
      log @params
      @params.each { |name,param|
        json = File.open(param.file).read
        json = JSON.pretty_generate(JsonPath.for(json).gsub(param.path) { |v| param.value }.to_hash)
        # 書き出し
        File.open(param.file,"w") { |f| f.write(json) }
        log "    write #{param.file}"
      }
    end

    def deploy
      ret = true
      Gargor.opt("target_nodes").each { |node|
        log "==> deploy to #{node}"
        cmd = Gargor.opt("target_cooking_cmd") % [node]
        log "    #{cmd}"
        r = system(cmd)
        unless r
          log "deploy failed"
          @fitness = 0
          sleep 1
        end
        ret &= r
      }
      ret
    end

    def shell command
      out = `command`
      ret = $?
      [out,ret]
    end

    def attack
      ret = nil;out = nil
      cmd = Gargor.opt('attack_cmd')
      log "==> attack"
      log "execute: #{cmd}"
      tms = Benchmark.realtime do
        out,ret = shell(cmd)
      end

      @fitness = Gargor.opt('evaluate_proc').call(ret.to_i,out,tms)
      log "fitness: #{@fitness}"
      @fitness
    end

    # a/b の確率でiを上書きする
    def overwrite_by i,a,b
      @params.each { |name,param|
        @params[name] = i.params[name] if a > Gargor.float_rand(b)
      }
      self
    end

  end
end
