# -*- coding: utf-8 -*-
require "gargor"
require "thor"
class Gargor
  class Double
    def method_missing(name, *arguments);end
  end

  class CLI < Thor
    default_command :tune
    class_option :verbose, :type => :boolean, :aliases =>:v

    desc "tune [gargor.rb]", "execute GA-search"
    option :no_progress_bar, :type => :boolean, :aliases =>:q
    option :max_generations, :type => :numeric, :aliases =>:g
    option :population, :type => :numeric, :aliases =>:p
    option :elite, :type => :numeric, :aliases =>:e
    option :mutation, :type => :numeric, :aliases =>:m
    option :target_cooking_cmd, :type =>:string, :banner =>"<COMMAND>"
    option :target_nodes, :type =>:string, :banner =>"<NODE1,NODE2,NODE3...>"
    option :attack_cmd, :type => :string, :banner =>"<COMMAND>"
    option :logger, :type =>:string, :banner =>"<FILE>"
    option :state, :type=>:string, :banner =>"<FILE>"

    def tune file="gargor.rb"
      require 'gargor/reporter'
      require 'progressbar'
      Gargor.start
      Gargor.load_dsl(file)
      Gargor.options = options

      pbar.set(0)
      trials
      best = best_individual
      deploy best 
      pbar.finish
      puts Gargor::OptimizeReporter.table(Gargor.base,best)
    rescue ExterminationError =>e
      recover
      report_error_exit(e)
    rescue =>e
      report_error_exit(e)
    end

    no_commands{
      def trials
        begin
          Gargor.populate.each { |i|
            trial(i) if i.fitness == nil 
            pbar.set(Gargor.total_trials-Gargor.last_trials)
          }
        end while(Gargor.next_generation)
      end

      def recover
        Gargor.base && deploy(Gargor.base)
      end

      def report_error_exit e,ret = 1
        unless $TESTING
          STDERR.puts e.message
          STDERR.puts e.backtrace.join("\n") if options["verbose"]
        end
        exit ret
      end

      def pbar
        @pbar = Double.new if options["no_progress_bar"]
        @pbar ||= ProgressBar.new(" Tuning",Gargor.total_trials)
      end

      def deploy i
        i.set_params
        i.deploy
      end

      def trial i
        deploy i
        i.attack
      rescue Gargor::DeployError =>e
        i.fitness = 0
      end

      def best_individual
        Gargor.individuals.max { |a,b| a.fitness <=> b.fitness }
      end
    }

  end
end
