require 'rest-client'
require 'json'
require 'pp'
require 'yaml'

# TODO: separate
class ApsisNode
  def initialize(url, pubkey)
    @url = url
    @pubkey = pubkey
    @headers = {}
    @headers = {content_type: :json, accept: :json}
  end

  def get_random_nodes()
    @path = "nodes/random"
    r = RestClient.get(url=@url+@path,
                       :params => {:pubkey => @pubkey},
                       :headers => @headers.merge({}))
    gen_response(r)
  end

  def post_node(payload)
    @path = 'nodes'
    r = RestClient.post(url=@url+@path,
                    payload.to_json,
                    headers=@headers.merge({}))
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
  def initialize(hosts_dir)
    @hosts_dir = hosts_dir
  end

  def get_pubkey(node)
    ed25519_token = 'Ed25519PublicKey = '
    File.open("#{@hosts_dir}/#{node}") do |f|
      f.each_line do |l|
        if l.start_with?(ed25519_token)
          return l.slice(ed25519_token.length..l.length).chomp
        end
      end
    end
  end
end

config = YAML.load_file('config.yml')

t = Tinc.new(config['tinc']['dir'])
pubk = t.get_pubkey(config['tinc']['node']) # retrieve my own pubkey

url = "http://apsis-exchange-hub/"

an = ApsisNode.new(url, pubk)

node = {keys: {ed25519: pubk}}

an.post_node(node) # publish own data to the server
candidate_nodes = an.get_random_nodes # fetch a random node
pp candidate_nodes
