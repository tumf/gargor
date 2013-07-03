class Gargor
  GLOBAL_OPTS = ["population","max_generations","target_nodes",
                 "attack_cmd","elite","mutation","target_cooking_cmd",
                 "fitness_precision"]

  GLOBAL_OPTS.each { |name| 
    define_method(name) { |val|
      Gargor.class_variable_set("@@#{name}", val)
    }
  }

  def log message,level=Logger::INFO
    Gargor.log(message,level)
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

  def logger *args, &block
    file = args.shift
    @@logger = Logger.new(Gargor.logfile(file),*args)
    block.call(@@logger) if block
  end

end
