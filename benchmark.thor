class Benchmark < Thor
  include Thor::Actions

  URL_PATTERN = /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*(:[0-9]{1,5})?(\/.*)$/ix

  
  desc 'execute URL', 'Executa o benchmark no endereço informado'
  method_option :requests, :type => :numeric, :default => 1000, :aliases => "-n"
  method_option :concurrency, :type => :numeric, :default => 10, :aliases => "-c"
  method_option :name, :type => :string, :default => 'benchmark'
  def execute(url)
    error("URL Informada não é válida, deve seguir o padrão (http|https)://endereço/") unless url =~ URL_PATTERN
    setup
    name = 'benchmark'
    
    say "Executando benchmark..."
    run "ab -r -n #{options[:requests]} -c #{options[:concurrency]} -g raw/#{options[:name]}.tsv -e raw/#{options[:name]}.csv #{url} > logs/#{options[:name]}.log"
  end

  protected
  def error(message)
    puts "Falha: #{message}"
    exit -1
  end

  def setup()
    empty_directory 'logs'
    empty_directory 'raw'
  end
end
