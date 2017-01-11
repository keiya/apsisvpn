require 'rest-client'
require 'json'
require 'pp'
require 'yaml'
require 'optparse'
require 'jwt'

# TODO: separate
class ApsisNode
  def initialize(url, pubkey)
    @url = url
    @pubkey = pubkey
    @headers = {content_type: :json, accept: :json}
  end

  def get_challenge()
    @path = "/jwt/challenge"
    r = RestClient.get(url=@url+@path,
                       :params => {:pubkey => @pubkey},
                       :headers => @headers.merge({}))
    resp = gen_response(r)
    #JWT.decode resp[:body], nil, false
    @headers[:Authorization] = 'Bearer ' + resp[:body]
    resp
  end

  def get_random_nodes()
    @path = "/nodes/random"
    params = {params: {pubkey: @pubkey}}
    r = RestClient.get(url=@url+@path,
                      params.merge(@headers))
    gen_response(r)
  end

  def post_node(payload)
    @path = '/nodes'
    params = {params: {pubkey: @pubkey}}
    r = RestClient.post(url=@url+@path,
                    payload.to_json,
                    params.merge(@headers))
    gen_response(r)
  end

  def debug()
    payload = "THIS is a test message"
    @path = '/nodes/debug'
    params = {params: {pubkey: @pubkey}}
    r = RestClient.get(@url+@path,
                      params.merge(@headers))
    gen_response(r)
  end

  private

  def gen_response(rest)
    fail Exception if rest.code >= 400
    {code: rest.code,
     cookies: rest.cookies,
     headers: rest.headers,
     body: rest.body}
  end
end

class Tinc
  def initialize(tinc_bin, tinc_conf_dir, node, netname=nil)
    @bin = tinc_bin
    @netname = netname

    if netname.nil?
      uuid = SecureRandom.uuid.split('-')
      # except uuid4 version&variant for maximize a entropy
      @netname = [uuid.first, uuid.last].join()[0,15]
      system("#{@bin} init #{@netname}")
    end

    @hosts_dir = "#{tinc_conf_dir}/#{netname}/hosts"
    @node_file = "#{@hosts_dir}/#{node}"

    @node = node
  end

  def pubkey()
    ed25519_token = 'Ed25519PublicKey = '
    File.open(@node_file) do |f|
      f.each_line do |l|
        if l.start_with?(ed25519_token)
          return l.slice(ed25519_token.length..l.length).chomp
        end
      end
    end
  end

  def host()
    node_file = ''
    File.open(@node_file) do |file|
      node_file = file.read
    end
    node_file
  end

  def write_host(file)
    File.open(@node_file, "w") do |f|
   # File.open('./' + @node, "w") do |f|
      f.puts(file)
    end
  end

  def connect(pubk)
    system("#{@bin} -n #{@netname} start")
  end

  def init()
  end

end

params = ARGV.getopts('','net:')

config = YAML.load_file('config.yml')

if params["net"].nil?
  t = Tinc.new('/usr/local/sbin/tinc',config['tinc']['dir'],config['tinc']['node'])
else
  t = Tinc.new('/usr/local/sbin/tinc',config['tinc']['dir'],config['tinc']['node'],params["net"])
end
pubk = t.pubkey
p pubk

an = ApsisNode.new(config['hub']['url'], pubk)
p an.get_challenge()
#p an.debug()
p an.get_random_nodes # fetch a random node

node = {version: 1, keys: {ed25519: pubk}, type: "tinc", tinc: {file: t.host}}

an.post_node(node) # publish own data to the server
#candidate_nodes = an.get_random_nodes # fetch a random node
#candidate_nodes
#
#response = JSON.parse(candidate_nodes[:body])
#
## this tinc instance is ours
#t = Tinc.new('/usr/local/sbin/tinc',config['tinc']['dir'], 'me')
#t.write_host(response['tinc']['file'])
#t.connect(pubk)
