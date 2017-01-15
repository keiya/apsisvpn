require 'rest-client'
require 'json'
require 'pp'
require 'yaml'
require 'optparse'
require 'jwt'
require 'digest/sha2'
require 'fileutils'

class ProofOfWork
  #@charset = (" ".."~").to_a
  @charset = ("0".."9").to_a

  def self.solve(target,maxlength)
    for i in 1..maxlength+1
      ProofOfWork.chain(ProofOfWork.product(i)) do |candidate|
        hashval = Digest::SHA256.hexdigest(candidate)
        if hashval.start_with?(target)
          return candidate
        end
      end
    end
    return nil
  end

  def self.chain(*iterables)
     for it in iterables
         if it.instance_of? String
             it.split("").each do |i|
                 yield i
             end
         else
             for elem in it
                 yield elem
             end
         end
     end
  end

  def self.product(max)
    strings = 1.upto(max).flat_map do |n|
      @charset.repeated_permutation(n).map(&:join)
    end
  end
end

class ApsisNode
  def initialize(url, pubkey)
    @url = url
    @pubkey = pubkey
    @headers = {content_type: :json, accept: :json}
  end

  def get_challenge()
    @path = "/jwt/challenge"
    params = {params: { pubkey: @pubkey }}
    r = RestClient.get(url=@url+@path,
                       params.merge(@headers))
    gen_response(r)
  end

  def get_random_node()
    @path = "/nodes/random"
    params = {params: {}}
    r = RestClient.get(url=@url+@path,
                      params.merge(@headers))
    parse gen_response(r)
  end

  def post_node(payload)
    @path = '/nodes'
    params = {params: {}}
    r = RestClient.post(url=@url+@path,
                    payload.to_json,
                    params.merge(@headers))
    gen_response(r)
  end

  def debug()
    payload = "THIS is a test message"
    @path = '/nodes/debug'
    params = {params: {}}
    r = RestClient.get(@url+@path,
                      params.merge(@headers))
    gen_response(r)
  end

  private

  def gen_response(rest)
    @jwt = rest.headers[:x_jwt]
    @decoded_jwt = JWT.decode @jwt, nil, false
    #p @decoded_jwt[0]['data']
    set_next_headers
    {code: rest.code,
     cookies: rest.cookies,
     headers: rest.headers,
     body: rest.body}
  end

  def set_next_headers
    @headers['X-PoW'] =  ProofOfWork.solve(@decoded_jwt[0]['data']['challenge'],5)
    @headers[:Authorization] = 'Bearer ' + @jwt
  end

  def parse(resp)
    if resp.dig(:headers,:content_type) == 'application/json'
      return JSON.parse(resp[:body], quirks_mode: true)
    end
    nil
  end

end

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

  def connect(node_name, node_ip, node_priv_ip)
    system("#{@bin} -n #{@netname} add Mode switch")
    system("#{@bin} -n #{@netname} add #{node_name}.Address #{node_ip}")
    system("#{@bin} -n #{@netname} add ConnectTo #{node_name}")
    #system("#{@bin} -n #{@netname} add #{node_name}.Subnet #{node_priv_ip}/32")
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

params = ARGV.getopts('','net:')

config = YAML.load_file('config.yml')

if params["net"].nil?
  t = Tinc.new('/usr/local/sbin/tinc',config['tinc']['dir'])
  mynode = t.init
  File.open('created_net.txt','a') do |f|
    f.puts t.netname
  end
else
  t = Tinc.new('/usr/local/sbin/tinc',config['tinc']['dir'],params["net"])
end
mynode_file = t.export
mynode_obj = Tinc.parse(mynode_file)
pubk = mynode_obj['Ed25519PublicKey']
puts "tinc.#{t.netname} with pubkey: #{pubk}"

an = ApsisNode.new(config['hub']['url'], pubk)
an.get_challenge()

node = {version: 1, keys: {ed25519: pubk}, type: "tinc", tinc: {file: mynode_file}}

candidate_node = {}
while candidate_node.nil? or candidate_node.empty? do
  begin
    an.post_node(node) # publish own data to the server
  rescue => e
    p e
  end

  begin
    candidate_node = an.get_random_node # fetch a random node
  rescue => e
    p e
  end
  sleep 1
end
t.import(candidate_node['tinc']['file'])
candnode_obj = Tinc.parse(candidate_node['tinc']['file'])
p candnode_obj

t.connect(candnode_obj['Name'], candidate_node['ip'], candidate_node['networks']['vpn']['gateway_ip'])
assigned_ip = candidate_node['networks']['vpn']['assigned_ip']
system({
  'SUBNET' => assigned_ip['subnet'].to_s,
  #'VPN_IP' => assigned_ip['ips'][0],
  'BRIDGE_IP' => assigned_ip['ips'][0],
  'VPN_IF' => t.netname,
  'BRIDGE_IF' => "#{t.netname}br"
}, "/usr/bin/env sh apsis-up.sh")
t.log
