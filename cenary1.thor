class Cenary1 < Thor
  include Thor::Actions
  include Graphs

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
    empty_directory 'graphs'
   
    # nginx - hits    
    options = {:service => 'nginx', :image => 'nginx', :title => 'Benchmark NGINX - Performance'}
    options[:files] = Dir.glob("logs/nginx-*.log").map{|f| File.basename(f, '.log')}.sort_by {|f| f.scan(/\d+/)[0].to_i }

    plot_log(options)
    
    
    # nginx - baixa concorrência
    options = {:image => 'nginx-low', :title => 'Benchmark NGINX - baixa concorrência'}
    options[:files] = Dir.glob("raw/nginx-??.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }

    plot_tsv(options)
    plot_csv(options)
    
    
    # nginx - alta concorrência
    options = {:image => 'nginx-high', :title => 'Benchmark NGINX - alta concorrência'}
    options[:files] = Dir.glob("raw/nginx-???.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }

    plot_tsv(options)
    plot_csv(options)
    
    
    # Apache2 - hits
    options = {:service => 'apache', :image => 'apache-perf', :title => 'Benchmark Apache2 - Performance'}
    options[:files] = Dir.glob("logs/apache-*.log").map{|f| File.basename(f, '.log')}.sort_by {|f| f.scan(/\d+/)[0].to_i }

    plot_log(options)


    # Apache 2 - baixa concorrência
    options = {:image => 'apache-low', :title => 'Benchmark Apache2 - baixa concorrência'}
    options[:files] = Dir.glob("raw/apache-??.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }
    
    plot_tsv(options)
    plot_csv(options)

    
    # Apache 2 - alta concorrência
    options = {:image => 'apache-high', :title => 'Benchmark Apache2 - alta concorrência'}
    options[:files] = Dir.glob("raw/apache-???.tsv").map{|f| File.basename(f, '.tsv')}.sort_by {|f| f.scan(/\d+/)[0].to_i }
    
    plot_tsv(options)
    plot_csv(options)
  end

  protected   
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
