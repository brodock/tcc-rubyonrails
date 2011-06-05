class Benchmark < Thor
  include Thor::Actions

  URL_PATTERN = /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*(:[0-9]{1,5})?(\/.*)$/ix

  
  desc 'execute URL', 'Executa o benchmark no endereço informado'
  method_option :requests, :type => :numeric, :default => 1000, :aliases => "-n"
  method_option :concurrency, :type => :numeric, :default => 10, :aliases => "-c"
  method_option :name, :type => :string, :default => 'benchmark'
  method_option :package, :type => :string, :default => ''
  def execute(url)
    raise ArgumentError, 'URL must follow pattern (http|https)://address/' unless url =~ URL_PATTERN
    setup(options[:package])
    
    package = options[:package].empty? ? '' : options[:package] + '/'
    
    say "Executando benchmark..."
    run "ab -r -k -n#{options[:requests]} -c #{options[:concurrency]} -g raw/#{package}#{options[:name]}.tsv -e raw/#{package}#{options[:name]}.csv #{url} > logs/#{package}#{options[:name]}.log"
  end

  protected
  def setup(package='')
    empty_directory 'logs'
    empty_directory 'raw'
    unless package.empty?
      empty_directory "logs/#{package}"
      empty_directory "raw/#{package}"
    end
  end
end
