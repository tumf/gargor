require 'terminal-table'
class Gargor
  class Reporter; end
  class OptimizeReporter < Reporter
    class << self
      def table(from, to)
        table = Terminal::Table.new headings: %w(param from to) do |t|
          from.params.each do |name, f|
            t << [name, f, to.params[name]]
          end
          t << :separator
          t << ['Fitness', from.fitness, to.fitness]
        end
        [1, 2].map { |n| table.align_column(n, :right) }
        table.style = { border_y: '', border_i: '-' }
        table
      end
    end
  end
end
