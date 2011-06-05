require 'lib/utils.rb'
require 'lib/graphs.rb'

class Cenary1 < Thor
  include Thor::Actions
  include Graphs
  include Utils

  # modelo de regexp para validar IP
  IP_PATTERN = /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/

  #
  # Benchmarks
  #
  
  desc 'nginx IP', 'Executa o benchmark do nginx no endereço informado'
  def nginx(machine_ip)
    raise ArgumentError, 'Endereço de IP inválido' unless machine_ip =~ IP_PATTERN

    url = "http://#{machine_ip}/"
    concurrency = (1..4).map{|x| x*20}
    concurrency += (1..5).map{|x| x*100}
    
    concurrency.each do |c|
        restart machine_ip, 'nginx'
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=nginx-#{c} --package=standalone"
    end
  end
  
  desc 'nginx_passenger IP', 'Executa o benchmark do nginx + Passenger no endereço informado'
  def nginx_passenger(machine_ip)
    raise ArgumentError, 'Endereço de IP inválido' unless machine_ip =~ IP_PATTERN

    url = "http://#{machine_ip}/"
    concurrency = (1..4).map{|x| x*20}
    concurrency << 100
    
    concurrency.each do |c|
        restart machine_ip, 'nginx'
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=nginx-passenger-#{c} --package=standalone"
    end
  end
  
  desc 'apache IP', 'Executa o benchmark do Apache2 no endereço informado'
  def apache(machine_ip)
    raise ArgumentError, 'Endereço de IP inválido' unless machine_ip =~ IP_PATTERN

    url = "http://#{machine_ip}/"
    concurrency = (1..4).map{|x| x*20}
    concurrency += (1..5).map{|x| x*100}
    
    concurrency.each do |c|
        restart machine_ip, 'apache2'
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=apache-#{c} --package=passenger"
    end
  end
  
  desc 'apache_passenger IP', 'Executa o benchmark do Apache2 + Passenger no endereço informado'
  def apache_passenger(machine_ip)
    raise ArgumentError, 'Endereço de IP inválido' unless machine_ip =~ IP_PATTERN

    url = "http://#{machine_ip}/"
    concurrency = (1..4).map{|x| x*20}
    concurrency += (1..5).map{|x| x*100}
    
    concurrency.each do |c|
        restart machine_ip, 'apache2'
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=apache-passenger-#{c} --package=passenger"
    end
  end
  
  desc 'graphs', 'Realiza a geração de todos os gráficos do cenário'
  def graphs()
    invoke 'graphs_standalone'
    invoke 'graphs_passenger'
  end

  #
  # Graficos - Servidor Standalone
  #
  
  desc 'graphs_standalone', 'Realiza a geração dos gráficos dos testes com servidores em standalone'
  def graphs_standalone()
    empty_directory 'graphs'
   
    # nginx - hits    
    options = {:image => 'nginx', :title => 'Benchmark NGINX - Performance'}    
    plot_log(options) { |plot| plot.data << log_dataset(find_files("logs/standalone/nginx-*.log"), 'nginx') }
    

    # nginx - baixa concorrência
    options = {:image => 'nginx-low', :title => 'Benchmark NGINX - baixa concorrência'}
    plot_tsv(options) { |plot| plot.data = tsv_datasets(find_files("raw/standalone/nginx-??.tsv")) }
    plot_csv(options) { |plot| plot.data = csv_datasets(find_files("raw/standalone/nginx-??.csv")) }

    
    # nginx - alta concorrência
    options = {:image => 'nginx-high', :title => 'Benchmark NGINX - alta concorrência'}
    plot_tsv(options) { |plot| plot.data = tsv_datasets(find_files("raw/standalone/nginx-???.tsv")) }
    plot_csv(options) { |plot| plot.data = csv_datasets(find_files("raw/standalone/nginx-???.csv")) }
    

    # Apache2 - hits
    options = {:image => 'apache', :title => 'Benchmark Apache2 - Performance'}
    plot_log(options) { |plot| plot.data << log_dataset(find_files("logs/standalone/apache-*.log"), 'apache') }


    # Apache 2 - baixa concorrência
    options = {:image => 'apache-low', :title => 'Benchmark Apache2 - baixa concorrência'}
    plot_tsv(options) { |plot| plot.data = tsv_datasets(find_files("raw/standalone/apache-??.tsv")) }
    plot_csv(options) { |plot| plot.data = csv_datasets(find_files("raw/standalone/apache-??.csv")) }

    
    # Apache 2 - alta concorrência
    options = {:image => 'apache-high', :title => 'Benchmark Apache2 - alta concorrência'}
    plot_tsv(options) { |plot| plot.data = tsv_datasets(find_files("raw/standalone/apache-???.tsv")) }
    plot_csv(options) { |plot| plot.data = csv_datasets(find_files("raw/standalone/apache-???.csv")) }
    
    
    # Apache2 vs Nginx - hits
    options = {:image => 'apache-vs-nginx', :title => 'Benchmark Apache2 vs NGINX - Performance'}
    plot_log(options) do |plot|
      plot.key "left bottom"
      plot.data << log_dataset(find_files("logs/standalone/apache-*.log"), 'apache')
      plot.data << log_dataset(find_files("logs/standalone/nginx-*.log"), 'nginx')
    end
  end
  
  #
  # Gráficos servidor + passenger
  #
  
  desc 'graphs_passenger', 'Realiza a geração dos gráficos dos testes com servidores com passenger'
  def graphs_passenger()
    empty_directory 'graphs'   
    
    # Apache2 + Passenger: hits
    options = {:image => 'apache-passenger', :title => 'Benchmark Apache2 + Passenger: Performance'}
    plot_log(options) { |plot| plot.data << log_dataset(find_files("logs/passenger/apache-passenger-*.log"), 'apache+passenger') }


    # Apache 2 + Passenger: baixa concorrência
    options = {:image => 'apache-low-passenger', :title => 'Benchmark Apache2 + Passenger: baixa concorrência'}
    plot_tsv(options) { |plot| plot.data = tsv_datasets(find_files("raw/passenger/apache-passenger-??.tsv")) }
    plot_csv(options) { |plot| plot.data = csv_datasets(find_files("raw/passenger/apache-passenger-??.csv")) }

    
    # Apache 2 + Passenger: alta concorrência
    options = {:image => 'apache-high-passenger', :title => 'Benchmark Apache2 + Passenger: alta concorrência'}    
    plot_tsv(options) { |plot| plot.data = tsv_datasets(find_files("raw/passenger/apache-passenger-???.tsv")) }
    plot_csv(options) { |plot| plot.data = csv_datasets(find_files("raw/passenger/apache-passenger-???.csv")) }
    

    # nginx + Passenger: hits    
    options = {:image => 'nginx-passenger', :title => 'Benchmark NGINX + Passenger - Performance'}
    plot_log(options) { |plot| plot.data << log_dataset(find_files("logs/passenger/nginx-passenger-*.log"), 'nginx+passenger') }
    
    
    # nginx + Passenger: baixa concorrência
    options = {:image => 'nginx-passenger-low', :title => 'Benchmark NGINX + Passenger: baixa concorrência'}
    plot_tsv(options) { |plot| plot.data = tsv_datasets(find_files("raw/passenger/nginx-passenger-??.tsv")) }
    plot_csv(options) { |plot| plot.data = csv_datasets(find_files("raw/passenger/nginx-passenger-??.csv")) }
    
    
    # nginx + Passenger: alta concorrência
    options = {:image => 'nginx-passenger-high', :title => 'Benchmark NGINX + Passenger: alta concorrência'}
    plot_tsv(options) { |plot| plot.data = tsv_datasets(find_files("raw/passenger/nginx-passenger-???.tsv")) }
    plot_csv(options) { |plot| plot.data = csv_datasets(find_files("raw/passenger/nginx-passenger-???.csv")) }
    
    # Apache2 + Passenger: Passenger vs Nginx + Passenger: hits
    options = {:image => 'apache-passenger-vs-nginx-passenger', :title => 'Benchmark Apache2 + Passenger vs NGINX + Passenger: Performance'}
    
    plot_log(options) do |plot|
      plot.data << log_dataset(find_files("logs/passenger/apache-passenger-*.log"), 'apache+passenger')
      plot.data << log_dataset(find_files("logs/passenger/nginx-passenger-*.log"), 'nginx+passenger')
    end
  end

  protected
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
