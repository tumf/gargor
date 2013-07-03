class Gargor
  class Dsl
    GLOBAL_OPTS = ["population","max_generations","target_nodes",
                   "attack_cmd","elite","mutation","target_cooking_cmd",
                   "fitness_precision"]

    GLOBAL_OPTS.each { |name| 
      define_method(name) { |*args|
        if args.count > 0
          instance_variable_set("@#{name}", args.shift)
        end
        instance_variable_get("@#{name}")
      }
    }
    attr_accessor :param_procs, :attack_proc, :evaluate_proc

    def initialize
      @param_procs = {}
      @attack_proc = nil
      @evaluate_proc = Proc.new { 0 }
      @fitness_precision = 100000000
      @population = 0
      @max_generations = 1
      @elite = 0
      @attack_cmd = "false"
      @target_nodes = []
    end

    def params
      result = {}
      GLOBAL_OPTS.map { |name| result[name] = send(name)  }
      result
    end

    def log message,level=Logger::INFO
      Gargor.log(message,level)
    end

    def param name,&block
      @param_procs[name] = block
    end

    def attack cmd,&block
      @attack_cmd = cmd
      @attack_proc = block
    end

    def evaluate &block
      @evaluate_proc = block
    end

    def logger *args, &block
      file = args.shift
      logger = Logger.new(Gargor.logfile(file),*args)
      block.call(logger) if block
      Gargor.logger = logger
    end
  end
end
