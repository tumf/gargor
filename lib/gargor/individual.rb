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

    def log message,level = Logger::INFO
      Gargor.log message,level
    end

    def load_now
      log "==> load current json"
      @params.each { |name,param|
        json = File.read(param.file)
        @params[name].value = JsonPath.on(json,param.path).first
      }
      self
    end

    def set_param param,json
      JSON.pretty_generate(JsonPath.for(json).gsub(param.path) { |v| param.value }.to_hash)
    end

    def set_params
      log "==> set params"
      jsons = {}
      @params.each { |name,param|
        unless jsons.has_key?(param.file)
          log "load #{param.file}"
          jsons[param.file] = File.read(param.file)
        end
        jsons[param.file] = set_param(param,jsons[param.file])
        log " #{name}: #{param}"
      }
      jsons.each { |file,json|
        File.open(file,"w") { |f| f.write(json) }
        log " write #{file}"
      }
    end

    def deploy
      Gargor.opt("target_nodes").each { |node|
        log "==> deploy to #{node}"
        cmd = Gargor.opt("target_cooking_cmd") % [node]
        log "    #{cmd}"
        out,r = shell(cmd)
        unless r == 0
          log "deploy failed",Logger::ERROR
          @fitness = 0
          sleep 1
          raise Gargor::DeployError
        end
      }
      true
    end

    def shell command
      out = `#{command}`
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
