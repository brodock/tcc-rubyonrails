module Graphs

  DEFAULT_OPTIONS = {:title => 'Benchmark', :image => 'benchmark'}
  
  def plot_tsv(options)
    require 'gnuplot'    
    raise ArgumentError, 'Hash expected' unless options.is_a? Hash
    
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.terminal "pngcairo enhanced size 800,700"
        plot.output   "graphs/#{options[:image]}.png"
        plot.key      "left"
        plot.title    options[:title]
        plot.xlabel   "requisições"
        plot.ylabel   "tempo de resposta (ms)"
        plot.grid     "y"
        plot.style     "fill transparent solid 0.5 noborder"
        
        plot.data = options[:files].map do |file|
          Gnuplot::DataSet.new() do |ds|
            ds.data = "\"raw/#{file}.tsv\""
            ds.using = "9"
            ds.smooth = "sbezier"
            ds.title = file
            ds.with = "lines"
            ds.linewidth = 3
          end         
        end
        
        yield plot if block_given?
        
      end
    end
  end
  
  def plot_csv(options)
    require 'gnuplot'
    raise ArgumentError, 'Hash expected' unless options.is_a? Hash
    
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.terminal "pngcairo enhanced size 800,700"
        plot.output   "graphs/#{options[:image]}-grouped.png"
        plot.key      "left"
        plot.title    options[:title]
        plot.xlabel   "% de requisições totais"
        plot.ylabel   "tempo médio de resposta (ms)"
        plot.grid     "y"
        plot.style    "fill transparent solid 0.5 noborder"
        plot.datafile "separator ','"
        
        
        plot.data = options[:files].map do |file|
          Gnuplot::DataSet.new() do |ds|
            ds.data = "\"raw/#{file}.csv\""
            ds.using = "2"
            ds.smooth = "sbezier"
            ds.title = file
            ds.with = "lines"
            ds.linewidth = 3
          end         
        end
        
        yield plot if block_given?
        
      end
    end
  end
  
  def plot_log(options)
    require 'gnuplot'
    raise ArgumentError, 'Hash expected' unless options.is_a? Hash
    
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.terminal "pngcairo enhanced size 800,700"
        plot.output   "graphs/#{options[:image]}-perf.png"
        plot.key      "left"
        plot.title    options[:title]
        plot.xlabel   "conexões concorrentes"
        plot.ylabel   "Requisições por segundo"
        plot.grid     "y"
        plot.style    "fill transparent solid 0.5 noborder"
    
        x = []
        y = []
        options[:files].map do |file|
          log = parse_ab_log(file)
          x << file.scan(/\d+/)[0].to_i
          y << log['Requests per second'].scan(/\d+^.|\d+\.\d+/)[0].to_i
        end
 
        plot.data << Gnuplot::DataSet.new([x,y]) do |ds|
          ds.title = options[:service]
          ds.with = "lines"
          ds.smooth = "sbezier"
          ds.linewidth = 3
        end
        
        yield plot if block_given?
      
      end
    end
  end
end
