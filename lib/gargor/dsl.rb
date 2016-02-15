require 'json'
class Gargor
  class Dsl
    GLOBAL_OPTS = %w(population max_generations target_nodes
                     attack_cmd elite mutation target_cooking_cmd
                     fitness_precision state).freeze

    GLOBAL_OPTS.each do |name|
      define_method(name) do |*args|
        instance_variable_set("@#{name}", args.shift) if args.count > 0
        instance_variable_get("@#{name}")
      end
    end
    def target_nodes(*args)
      return @target_nodes if args.count == 0
      nodes = args.shift
      @target_nodes = if nodes.is_a? Array
                        nodes
                      else
                        nodes.split(',')
                      end
    end

    attr_accessor :param_procs, :attack_proc, :evaluate_proc

    def initialize
      @param_procs = {}
      @attack_proc = nil
      @evaluate_proc = proc { 0 }
      @fitness_precision = 100_000_000
      @population = 0
      @max_generations = 1
      @elite = 0
      @attack_cmd = 'false'
      @target_nodes = []
      @state = nil
    end

    def params
      result = {}
      GLOBAL_OPTS.map { |name| result[name] = send(name) }
      result
    end

    def options=(options)
      GLOBAL_OPTS.each do |name|
        send(name.to_sym, options[name]) if options.key?(name)
      end
    end

    def log(message, level = Logger::INFO)
      Gargor.log(message, level)
    end

    def param(name, &block)
      @param_procs[name] = block
    end

    def attack(cmd, &block)
      @attack_cmd = cmd
      @attack_proc = block
    end

    def evaluate(&block)
      @evaluate_proc = block
    end

    def logger(*args, &block)
      file = args.shift
      logger = Logger.new(Gargor.logfile(file), *args)
      yield(logger) if block
      Gargor.logger = logger
    end

    def has_state?
      !!@state
    end

    def create_individual(values = nil)
      individual = Individual.new
      param_procs.each do |name, proc|
        param = Parameter.new(name)
        param.instance_eval(&proc)
        values && param.value = values[name]
        individual.params[name] = param
      end
      individual
    end

    def load_state(file = @state)
      log "load state #{file}"
      state = JSON.parse(File.read(file))
      individuals = Individuals.new
      state.each do |i|
        individuals << create_individual(i)
      end
      individuals
    rescue Errno::ENOENT => e
      false
    end

    def save_state(individuals, file = @state)
      log "save state #{file}"
      json = individuals.to_json
      File.open(file, 'w') { |f| f.write(json) }
    end
  end
end
