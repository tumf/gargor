# -*- coding: utf-8 -*-
require "gargor/version"
require "gargor/individual"
require "gargor/parameter"

class Gargor
  GLOBAL_OPTS = ["population","max_generations","target_nodes",
                 "attack_cmd","elite","mutation","target_cooking_cmd",
                 "attack_node","fitness_precision","attack_result"]

  GLOBAL_OPTS.each { |name| 
    define_method(name) { |val|
      Gargor.class_variable_set("@@#{name}", val)
    }
  }

  class << self
    def start
      @@fitness_precision = 100000000
      @@prev_generation = nil
      @@individuals = []
      @@param_procs = {}
      @@population = 10
      @@max_generations = 1
      @@generation = 1
      @@elite = 0
      @@attack_cmd = "false"
      @@attack_proc = nil
      @@evaluate_proc = nil
    end

    def load_dsl(params_file)
      contents = File.open(params_file, 'rb'){ |f| f.read }
      new.instance_eval(contents)
    end

    def mutation
      individual = Individual.new
      @@param_procs.each { |name,proc|
        param =  Parameter.new(name)
        param.instance_eval(&proc)
        individual.params[name] = param
      }
      individual
    end

    # 浮動小数点対応のrand
    def float_rand(f,p = @@fitness_precision)
      f *= @@fitness_precision
      i = f.to_i
      f = rand(i)
      f / @@fitness_precision.to_f
    end

    def crossover a,b
      return a.clone if a.params == b.params

      total = a.fitness + b.fitness
      c = Individual.new
      c.params = a.params.clone

      c.params.each { |name,param|
        cur = float_rand(total)
        c.params[name] = b.params[name] if b.fitness > cur
      }
      puts "#{a.to_s} + #{b.to_s} \n    => #{c.to_s}"
      c
    end

    def selection g
      total = g.inject(0) { |sum,i| sum += i.fitness }
      cur = float_rand(total)
      g.each { |i|
        return i if i.fitness > cur
        cur -= i.fitness
      }
      raise "error selection"
    end

    def populate
      @@individuals = []
      
      # 第一世代
      unless @@prev_generation
        @@individuals << mutation.load_now
        loop{
          break if @@individuals.length >= @@population
          @@individuals << mutation
        }
        return @@individuals
      end

      # fitness > 0 適応している個体
      prev_count = @@prev_generation.select { |i| i.fitness > 0 }.count

      if prev_count < 2
        raise "***** EXTERMINATION ******"
      end

      puts "population: #{@@prev_generation.length}"
      @@individuals = @@prev_generation.sort{ |a,b| a.fitness<=>b.fitness }.last(@@elite) if @@elite > 0
      loop{
        break if @@individuals.length >= @@population
        if rand <= @@mutation
          i =  mutation
        else
          a = selection @@prev_generation
          b = selection @@prev_generation
          i = crossover(a,b)
        end

        #同じのは追加しない
        @@individuals << i unless @@individuals.find { |ii| ii.params == i.params }
      }

      @@individuals
    end


    def next_generation
      puts "<== end generation #{@@generation}"
      @@generation += 1
      return false if @@generation > @@max_generations

      puts "==> next generation #{@@generation}"
      @@prev_generation = @@individuals
      true
    end

    def individuals
      @@individuals
    end

    def opt name
      Gargor.class_variable_get("@@#{name}")
    end
  end

  def param name,&block
    @@param_procs[name] = block
  end

  def attack cmd,&block
    @@attack_cmd = cmd
    @@attack_proc = block
  end

  def evaluate &block
    @@evaluate_proc = block
  end
end
