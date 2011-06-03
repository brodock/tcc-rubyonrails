class Cenary1 < Thor
  include Thor::Actions

  IP_PATTERN = /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/

  desc 'nginx IP', 'Executa o benchmark pré-definido no endereço informado'
  def nginx(machine_ip)
    error 'Endereço de IP inválido' unless machine_ip =~ IP_PATTERN

    url = "http://#{machine_ip}/"

    concurrency = (1..50).map{|x| x*10} # 10, 20, 30, ..., 500
    concurrency.each do |c|
        restart machine_ip
        thor :benchmark, :execute, "#{url} -n 30000 -c #{c} --name=nginx-#{c}"
    end
  end

  protected
  def error(message)
    puts "Falha: #{message}"
    exit -1
  end

  def restart(ip)
    url = "http://#{ip}/"
    say "Reiniciando serviço do nginx..."
    run "ssh root@#{ip} \"service nginx restart\""
    sleep 3

    say "Realizando o aquecimento da máquina #{ip}..."
    run "ab -r -n 100 -c 10 #{url} > /dev/null"
    sleep 3
  end

end
