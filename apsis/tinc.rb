require 'fileutils'

class Tinc
  attr_reader :netname, :me
def initialize(tinc_bin, tinc_conf_dir, netname=nil)
    @bin = tinc_bin
    @netname = netname

    if @netname.nil?
      netuuid = SecureRandom.uuid.split('-')
      # except uuid4 version&variant for maximize a entropy
      @netname = [netuuid.first, netuuid.last].join()[0,13]
    end

    @net_dir = "#{tinc_conf_dir}/#{@netname}"
    @hosts_dir = "#{@net_dir}/hosts"
  end

  def import(data)
    IO.popen("#{@bin} -n #{@netname} import", 'r+') do |io|
       io.write(data)
       io.close_write
    end
  end

  def export
    IO.popen("#{@bin} -n #{@netname} export", 'r') do |io|
       return io.read
    end
  end

  def connect(node_name, node_ip, node_port, vpn, bind_addr, bind_port)
    system("#{@bin} -n #{@netname} add Mode switch")
    system("#{@bin} -n #{@netname} add BindToAddress #{bind_addr} #{bind_port}")
    system("#{@bin} -n #{@netname} add #{node_name}.Address #{node_ip} #{node_port}")
    system("#{@bin} -n #{@netname} add ConnectTo #{node_name}")
    system("#{@bin} -n #{@netname} add #{node_name}.Subnet 0.0.0.0/0")
    system("#{@bin} -n #{@netname} start")
  end

  def log
    system("#{@bin} -n #{@netname} log 5")
  end

  def disconnect
    system("#{@bin} -n #{@netname} stop")
  end

  def init
    node_uuid = SecureRandom.uuid.split('-')
    node_name = [node_uuid.first, node_uuid.last].join()
    system("#{@bin} -n #{@netname} init #{node_name}")

    FileUtils.cp('templates/tinc-up', "#{@net_dir}/tinc-up")
    FileUtils.cp('templates/tinc-down', "#{@net_dir}/tinc-down")
    FileUtils.chmod('ugo+x', "#{@net_dir}/tinc-up")
    FileUtils.chmod('ugo+x', "#{@net_dir}/tinc-down")
    node_name
  end

  def self.parse(str)
    hash = {}
    str.each_line do |l|
      pair = l.split('=')
      pair.map! {|e| e.delete(' ').chomp}
      hash[pair[0]] = pair[1]
    end
    hash
  end

end
