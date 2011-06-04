module Utils

  # modelo de regexp para extrair valores do log do Apache Benchmark
  AB_LOG_PATTERN = /^([a-zA-Z]+[\s\-a-zA-Z]+):\s+(.+)/
  
  def find_files(file_pattern)
    Dir.glob(file_pattern).map{|f| File.basename(f, File.extname(f))}.sort_by {|f| f.scan(/\d+/)[0].to_i }
  end
  
  def error(message)
    puts "Falha: #{message}"
    exit -1
  end
  
  def parse_ab_log(file)
    f = File.open("logs/#{file}.log").read().scan(AB_LOG_PATTERN)
    Hash[*f.collect {|a,b| [a,b]}.flatten]
  end
end
