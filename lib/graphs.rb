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
        plot.xlabel   "Requisições"
        plot.ylabel   "Tempo de resposta (ms)"
        plot.grid     "y"
        plot.style     "fill transparent solid 0.5 noborder"
        
        plot.data = tsv_datasets(options[:files])
        
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
        plot.ylabel   "Tempo médio de resposta (ms)"
        plot.grid     "y"
        plot.style    "fill transparent solid 0.5 noborder"
        plot.datafile "separator ','"
        
        plot.data = csv_datasets(options[:files])
        
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
        plot.xlabel   "Conexões concorrentes"
        plot.ylabel   "Requisições por segundo"
        plot.grid     "y"
        plot.style    "fill transparent solid 0.5 noborder"
                
        yield plot if block_given?
      
      end
    end
  end
  
  protected
  
  def tsv_datasets(files)
    files.map do |file|
      Gnuplot::DataSet.new() do |ds|
        ds.data = "\"raw/#{file}.tsv\""
        ds.using = "9"
        ds.smooth = "sbezier"
        ds.title = file
        ds.with = "lines"
        ds.linewidth = 3
      end         
    end
  end
  
  def csv_datasets(files)
    files.map do |file|
      Gnuplot::DataSet.new() do |ds|
        ds.data = "\"raw/#{file}.csv\""
        ds.using = "2"
        ds.smooth = "sbezier"
        ds.title = file
        ds.with = "lines"
        ds.linewidth = 3
      end         
    end
  end
  
  def log_dataset(files, title)
    x = []
    y = []
    files.map do |file|
      log = parse_ab_log(file)
      x << file.scan(/\d+/)[0].to_i
      y << log['Requests per second'].scan(/\d+^.|\d+\.\d+/)[0].to_i
    end

    Gnuplot::DataSet.new([x,y]) do |ds|
      ds.title = title
      ds.with = "lines"
      ds.smooth = "sbezier"
      ds.linewidth = 3
    end
  end
end
