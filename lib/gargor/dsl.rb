class Gargor
  class Dsl
    GLOBAL_OPTS = ["population","max_generations","target_nodes",
                   "attack_cmd","elite","mutation","target_cooking_cmd",
                   "fitness_precision","state"]

    GLOBAL_OPTS.each { |name| 
      define_method(name) { |*args|
        if args.count > 0
          instance_variable_set("@#{name}", args.shift)
        end
        instance_variable_get("@#{name}")
      }
    }
    def target_nodes *args
      return @target_nodes if args.count == 0
      nodes = args.shift
      @target_nodes = if nodes.is_a? Array
                        nodes
                      else
                        nodes.split(",")
                      end
    end

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
      @state = nil
    end

    def params
      result = {}
      GLOBAL_OPTS.map { |name| result[name] = send(name)  }
      result
    end

    def options= options
      GLOBAL_OPTS.each { |name|
        send(name.to_sym,options[name]) if options.has_key?(name)
      }
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
