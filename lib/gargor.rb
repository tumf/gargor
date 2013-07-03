# -*- coding: utf-8 -*-
require 'rubygems' if RUBY_VERSION < '1.9'
require "logger"

require "gargor/version"
require "gargor/individual"
require "gargor/parameter"
require "gargor/exceptions"
require "gargor/individuals"
require "gargor/dsl"

class Gargor
  class << self
    def log message,level=Logger::INFO
      return if $TESTING
      message.to_s.split("\n").each { |line| @@logger.add(level) {line} }
    end

    def debug message
      log message,Logger::DEBUG
    end

    def params
      result = {}
      GLOBAL_OPTS.map { |name| 
        result[name] = Gargor.class_variable_get("@@#{name}")
      }
      result
    end

    def start
      @@logger = Logger.new(STDOUT)
      @@fitness_precision = 100000000
      @@prev_generation = nil
      @@individuals = []
      @@param_procs = {}
      @@population = 0
      @@max_generations = 1
      @@generation = 1
      @@elite = 0
      @@attack_cmd = "false"
      @@attack_proc = nil
      @@evaluate_proc = Proc.new { 0 }
      @@target_nodes = []
      @@dsl_file = nil
      true
    end
    Gargor.start

    def validate
      raise ValidationError,"POPULATION isn't > 0" unless @@population > 0
      true
    end

    def first_generation?
      @@generation == 1
    end

    # 前世代の数
    def prev_count g = @@prev_generation
      # fitness > 0 適応している個体
      g.select { |i| i.fitness && i.fitness > 0 }.count
    end

    def load_dsl(params_file)
      @@dsl_file = params_file
      contents = File.read(params_file)
      new.instance_eval(contents)
      validate
    end

    def mutate
      individual = Individual.new
      @@param_procs.each { |name,proc|
        param =  Parameter.new(name)
        param.instance_eval(&proc)
        individual.params[name] = param
      }
      log "mutate #{individual}"
      individual
    end

    # 浮動小数点対応のrand
    def float_rand(f,p = @@fitness_precision)
      raise ArgumentError,"max must be > 0" unless f > 0
      f *= @@fitness_precision
      i = f.to_i
      f = rand(i)
      f / @@fitness_precision.to_f
    end

    def crossover a,b
      return a.clone if a.params == b.params
      log "crossover: #{a} #{b}"
      total = a.fitness + b.fitness
      c = Individual.new
      c.params = a.params.clone
      c.overwrite_by(b,b.fitness,total)
    end

    def selection g
      total = g.inject(0) { |sum,i| sum += i.fitness }
      cur = float_rand(total)
      g.each { |i|
        return i if i.fitness > cur
        cur -= i.fitness
      }
      raise GargorError,"error selection"
    end

    def populate_first_generation
      individuals = Gargor::Individuals.new
      individuals << mutate.load_now
      loop{
        break if individuals.length >= @@population
        individuals << mutate
      }
      
      Gargor::Individuals.new(individuals.shuffle)
    end

    def select_elites g,count
      return [] unless count > 0
      Gargor::Individuals.new(g.sort{ |a,b| a.fitness<=>b.fitness }.last(count))
    end

    def mutation? mutation=@@mutation
      rand <= mutation
    end

    def select_parents g
      [selection(g),selection(g)]
    end

    def populate_one
      if mutation?
        mutate
      else
        crossover(*select_parents(@@prev_generation))
      end
    end

    def populate_next_generation
      log "population: #{@@prev_generation.length}"
      individuals = Gargor::Individuals.new(select_elites @@prev_generation,@@elite)

      until individuals.length >= @@population do
        i = populate_one
        individuals << i unless individuals.has?(i)
      end
      Gargor::Individuals.new(individuals.shuffle)
    end

    def populate
      @@individuals = if first_generation?
                        # 第一世代
                        populate_first_generation
                      else
                        # 次世代
                        raise ExterminationError unless prev_count >= 2
                        populate_next_generation
                      end
      log "populate:"
      @@individuals.each { |i| log i }
    end


    def next_generation
      log "<== end generation #{@@generation}"
      @@generation += 1
      return false if @@generation > @@max_generations

      log "==> next generation #{@@generation}"
      @@prev_generation = @@individuals
      true
    end

    def individuals
      @@individuals
    end

    def opt name
      Gargor.class_variable_get("@@#{name}")
    end

    def logfile file
      File.expand_path(File.join(File.dirname(@@dsl_file),file))
    end

    def total_trials
      @@population+(@@population-@@elite)*(@@max_generations-1)
    end

    def last_trials_at_this_generation
      @@individuals.select{ |i| i.fitness == nil }.count
    end

    def last_trials
      last_trials_at_this_generation +
        (@@max_generations-@@generation)*(@@population-@@elite)
    end

  end
end
