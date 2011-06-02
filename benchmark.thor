class Benchmark < Thor
  include Thor::Actions
  
  desc "execute URL", "Executa o benchmark no endereço informado"
  method_option :requests, :type => :numeric, :default => 1000, :aliases => "-n"
  method_option :concurrency, :type => :numeric, :default => 10, :aliases => "-c"
  def execute(url)
    run "ab -r -n #{options[:requests]} -c #{options[:concurrency]} #{url} -g logs/benchmark.dat"
  end
end
