module Utils

  # modelo de regexp para extrair valores do log do Apache Benchmark
  AB_LOG_PATTERN = /^([a-zA-Z]+[\s\-a-zA-Z]+):\s+(.+)/
  
  # Realiza a listagem de arquivos de um determinado diretório, seguindo o padrão informado.
  # Os arquivos são ordenados pela sua numeração e armazenados sem extensão e sem caminho
  def find_files(file_pattern)
    Dir.glob(file_pattern).map{|f| File.basename(f, File.extname(f))}.sort_by {|f| f.scan(/\d+/)[0].to_i }
  end
  
  # Exibe uma mensagem de erro e finaliza a aplicação
  def error(message)
    puts "Falha: #{message}"
    exit -1
  end
  
  # Abre o arquivo de log informado e captura todas as tuplas "<Nome da métrica>: <Valor da Métrica>"
  def parse_ab_log(file)
    f = File.open("logs/#{file}.log").read().scan(AB_LOG_PATTERN)
    Hash[*f.collect {|a,b| [a,b]}.flatten]
  end
end