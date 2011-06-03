class Cenary1 < Thor
  include Thor::Actions

  desc 'execute URL', 'Executa o benchmark pré-definido no endereço informado'
  def execute(url)
    concurrency = (1..50).map{|x| x*10} # 10, 20, 30, ..., 500
    concurrency.each do |c|
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=nginx-#{c}"
    end
  end

end
