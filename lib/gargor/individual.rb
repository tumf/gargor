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

    def set_param param
      File.open(param.file,"rw") { |f|
        json = JSON.pretty_generate(JsonPath.for(f.read).gsub(param.path) { |v| param.value }.to_hash)
        f.write(json)
      }
    end

    def set_params
      log "==> set params"
      log @params
      @params.each { |name,param|
        set_param(param)
        log "#{name}    write #{param.file}"
      }
    end

    def deploy
      Gargor.opt("target_nodes").each { |node|
        log "==> deploy to #{node}"
        cmd = Gargor.opt("target_cooking_cmd") % [node]
        log "    #{cmd}"
        out,r = shell(cmd)
        unless r == 0
          log "deploy failed"
          @fitness = 0
          sleep 1
          return false
        end
      }
      true
    end

    def shell command
      out = `command`
      ret = $?
      [out,ret.exitstatus]
    end

    def attack
      ret = nil;out = nil
      cmd = Gargor.opt('attack_cmd')
      log "==> attack"
      log "execute: #{cmd}"
      tms = Benchmark.realtime do
        out,ret = shell(cmd)
      end

      @fitness = Gargor.opt('evaluate_proc').call(ret,out,tms)
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
