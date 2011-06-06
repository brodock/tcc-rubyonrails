require 'lib/utils.rb'
require 'lib/graphs.rb'

class Cenario2 < Thor
  include Thor::Actions
  include Graphs
  include Utils

  # modelo de regexp para validar IP
  IP_PATTERN = /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/
  
  # modelo de regexp para aceitar somente 'pequeno', 'médio' ou 'grande'
  MACHINE_PATTERN = /^(medio|grande|enorme)$/
  
  #
  # Benchmarks
  #  
  
  desc 'teste1 IP Tamanho_da_VM', 'Executa o benchmark do Teste1, para máquina pequena, no endereço informado'
  def teste1(machine_ip, machine_template)
    raise ArgumentError, 'Endereço de IP inválido' unless machine_ip =~ IP_PATTERN
    raise ArgumentError, 'Somente os tamanhos "medio", "grande" ou "enorme"' unless machine_template =~ MACHINE_PATTERN

    url = "http://#{machine_ip}/"
    concurrency = (1..4).map{|x| x*25}
    
    concurrency.each do |c|
        restart machine_ip, 'apache2'
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=teste1-#{machine_template}-#{c} --package=cenario2"
    end
  end
  
  desc 'teste2 IP Tamanho_da_VM', 'Executa o benchmark do Teste1, para máquina pequena, no endereço informado'
  def teste2(machine_ip, nodes)
    raise ArgumentError, 'Endereço de IP inválido' unless machine_ip =~ IP_PATTERN

    url = "http://#{machine_ip}/"
    concurrency << 50
    
    concurrency.each do |c|
        restart machine_ip, 'apache2'
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=teste2-nodes#{nodes}-#{c} --package=cenario2"
    end
  end
  
  
  #
  # Gráficos
  #
  
  desc 'graphs',  'Realiza a geração dos gráficos dos testes deste cenário'
  def graphs()
    empty_directory 'graphs' 
    machines = %w(medio grande enorme)    
    # Teste 1 Tamanhos: pequeno, medio, grande
    machines.each do |machine|
    
        options = {:image => "teste1-#{machine}", :title => "Benchmark Cenário 2 - Teste1 - #{machine}: Performance"}    
        plot_log(options) do |plot|
          plot.data << log_dataset(find_files("logs/cenario2/teste1-#{machine}-*.log"), machine)
        end
        
        options = {:image => "teste1-#{machine}", :title => "Benchmark Cenário 2 - Teste1 - #{machine}: Performance"}    
        plot_tsv(options) { |plot| plot.data = tsv_datasets(find_files("raw/cenario2/teste1-#{machine}-*.tsv")) }
        plot_csv(options) { |plot| plot.data = csv_datasets(find_files("raw/cenario2/teste1-#{machine}-*.csv")) }
    
    end
    options = {:image => "teste1-grouped", :title => "Benchmark Cenário 2 - Teste1: Performance"}    
    plot_log(options) do |plot|
      machines.each do |machine|
        plot.data << log_dataset(find_files("logs/cenario2/teste1-#{machine}-*.log"), machine)
      end
    end
  end
  
  protected
  def restart(ip, service_name)
    url = "http://#{ip}/"
    say "Reiniciando #{service_name}..."
    run "ssh root@#{ip} \"service #{service_name} restart\""
    sleep 5

    say "Realizando o aquecimento da máquina #{ip}..."
    run "ab -r -n 2000 -c 10 #{url} > /dev/null"
    sleep 20
  end
end
