class Cenary1 < Thor
  include Thor::Actions

  # modelo de regexp para validar IP
  IP_PATTERN = /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/
  # modelo de regexp para extrair valores do log do Apache Benchmark
  AB_LOG_PATTERN = /^([a-zA-Z]+[\s\-a-zA-Z]+):\s+(.+)/

  desc 'nginx IP', 'Executa o benchmark pré-definido no endereço informado'
  def nginx(machine_ip)
    error 'Endereço de IP inválido' unless machine_ip =~ IP_PATTERN

    url = "http://#{machine_ip}/"

    concurrency = (1..4).map{|x| x*20}
    concurrency += (1..5).map{|x| x*100}
    concurrency.each do |c|
        restart machine_ip, 'nginx'
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=nginx-#{c}"
    end
  end
  
  desc 'apache IP', 'Executa o benchmark pré-definido no endereço informado'
  def apache(machine_ip)
    error 'Endereço de IP inválido' unless machine_ip =~ IP_PATTERN

    url = "http://#{machine_ip}/"

    concurrency = (1..4).map{|x| x*20}
    concurrency += (1..5).map{|x| x*100}
    concurrency.each do |c|
        restart machine_ip, 'apache2'
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=apache-#{c}"
    end
  end
  
  desc 'graphics', 'Realiza a geração dos gráficos a partir dos testes realizados'
  def graphics()
    empty_directory 'graphics'
   
    # nginx - hits
    
    title = 'Benchmark NGINX - Performance'
    image = 'nginx-perf'
    service = 'nginx'
    files = Dir.glob("logs/nginx-*.log").map{|f| File.basename(f, '.log')}.sort_by {|f| f.scan(/\d+/)[0].to_i }

    plot_log(image, title, service, files)
    
    # nginx - baixa concorrência
    
    title = 'Benchmark NGINX - baixa concorrência'
    image = 'nginx-low'
    files = Dir.glob("raw/nginx-??.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }

    plot_tsv(image, title, files)
    plot_csv(image, title, files)
    
    # nginx - alta concorrência

    title = 'Benchmark NGINX - alta concorrência'
    image = 'nginx-high'
    files = Dir.glob("raw/nginx-???.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }

    plot_tsv(image, title, files)
    plot_csv(image, title, files)

    # Apache 2 - baixa concorrência
    
    title = 'Benchmark Apache2 - baixa concorrência'
    image = 'apache-low'
    files = Dir.glob("raw/apache-??.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }
    
    plot_tsv(image, title, files)
    plot_csv(image, title, files)
    
    # Apache 2 - alta concorrência
    
    title = 'Benchmark Apache2 - alta concorrência'
    image = 'apache-high'
    files = Dir.glob("raw/apache-???.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }
    
    plot_tsv(image, title, files)
    plot_csv(image, title, files)
  end

  protected
  def plot_tsv(image, title, datafiles)
    require 'gnuplot'
    
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.terminal "pngcairo enhanced size 800,700"
        plot.output   "graphics/#{image}.png"
        plot.key      "left"
        plot.title    title
        plot.xlabel   "requisições"
        plot.ylabel   "tempo de resposta (ms)"
        plot.grid     "y"
        plot.style     "fill transparent solid 0.5 noborder"
        
        
        plot.data = datafiles.map do |f|
          Gnuplot::DataSet.new() do |ds|
            ds.data = "\"raw/#{f}.tsv\""
            ds.using = "9"
            ds.smooth = "sbezier"
            ds.title = f
            ds.with = "lines"
            ds.linewidth = 3
          end         
        end
        
      end
    end
  end
  
  def plot_csv(image, title, datafiles)
    require 'gnuplot'
    
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.terminal "pngcairo enhanced size 800,700"
        plot.output   "graphics/#{image}-grouped.png"
        plot.key      "left"
        plot.title    title
        plot.xlabel   "% de requisições totais"
        plot.ylabel   "tempo médio de resposta (ms)"
        plot.grid     "y"
        plot.style    "fill transparent solid 0.5 noborder"
        plot.datafile "separator ','"
        
        
        plot.data = datafiles.map do |f|
          Gnuplot::DataSet.new() do |ds|
            ds.data = "\"raw/#{f}.csv\""
            ds.using = "2"
            ds.smooth = "sbezier"
            ds.title = f
            ds.with = "lines"
            ds.linewidth = 3
          end         
        end
        
      end
    end
  end
  
  def plot_log(image, title, service, datafiles)
    require 'gnuplot'
    
      Gnuplot.open do |gp|
        Gnuplot::Plot.new( gp ) do |plot|
          plot.terminal "pngcairo enhanced size 800,700"
          plot.output   "graphics/#{image}-hits.png"
          plot.key      "left"
          plot.title    title
          plot.xlabel   "nível de concorrência"
          plot.ylabel   "Requisições por segundo"
          plot.grid     "y"
          plot.style    "fill transparent solid 0.5 noborder"
      
          x = []
          y = []
          datafiles.map do |f|
            log = parse_ab_log(f)
            x << f.scan(/\d+/)[0].to_i
            y << log['Requests per second'].scan(/\d+^.|\d+\.\d+/)[0].to_i
          end
   
          plot.data << Gnuplot::DataSet.new([x,y]) do |ds|
            ds.title = service
            ds.with = "lines"
            ds.smooth = "sbezier"
            ds.linewidth = 3
          end
        
        end
      end
  end
  
  def error(message)
    puts "Falha: #{message}"
    exit -1
  end

  def restart(ip, service_name)
    url = "http://#{ip}/"
    say "Reiniciando serviço do nginx..."
    run "ssh root@#{ip} \"service #{service_name} restart\""
    sleep 5

    say "Realizando o aquecimento da máquina #{ip}..."
    run "ab -r -n 2000 -c 10 #{url} > /dev/null"
    sleep 5
  end
  
  def parse_ab_log(file)
    f = File.open("logs/#{file}.log").read().scan(AB_LOG_PATTERN)
    Hash[*f.collect {|a,b| [a,b]}.flatten]
  end

end
