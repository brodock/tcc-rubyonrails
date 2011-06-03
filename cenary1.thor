class Cenary1 < Thor
  include Thor::Actions

  IP_PATTERN = /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/

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

    concurrency = (1..5).map{|x| x*100}
    concurrency.each do |c|
        restart machine_ip, 'apache2'
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=apache-#{c}"
    end
  end
  
  desc 'graphics', 'Realiza a geração dos gráficos a partir dos testes realizados'
  def graphics()
    empty_directory 'graphics'
    
    # nginx
    
    title = 'Benchmark Nginx'
    image = 'nginx'
    files = Dir.glob("raw/nginx-*.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }

    plot_tsv(image, title, files)
    plot_csv(image, title+' - duration', files)

    # Apache 2
    
    title = 'Benchmark Apache2'
    image = 'apache'
    files = Dir.glob("raw/apache-*.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }
    
    plot_tsv(image, title, files)
    plot_csv(image, title+' - duration', files)
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
        plot.output   "graphics/#{image}-duration.png"
        plot.key      "left"
        plot.title    title
        plot.xlabel   "requisições"
        plot.ylabel   "tempo de resposta (ms)"
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

end
