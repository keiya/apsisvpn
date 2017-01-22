#require 'pp'
require 'yaml'
require 'optparse'
require './apsis/proof-of-work'
require './apsis/exchanger'
require './apsis/tinc'

options = {}
OptionParser.new do |opts|
  opts.on("-n", "--net", "network") do |v|
    options[:net] = v
  end
end.parse!

config = YAML.load_file('config.yml')

if options["net"].nil?
  t = Tinc.new('/usr/local/sbin/tinc',config['tinc']['dir'])
  mynode = t.init
  File.open('created_net.txt','a') do |f|
    f.puts t.netname
  end
else
  t = Tinc.new('/usr/local/sbin/tinc',config['tinc']['dir'],options["net"])
end
mynode_file = t.export
mynode_obj = Tinc.parse(mynode_file)
pubk = mynode_obj['Ed25519PublicKey']
puts "tinc.#{t.netname} with pubkey: #{pubk}"

ex = Exchanger.new(config['hub']['url'], pubk)
p ex.get_challenge()

node = {version: 1, keys: {ed25519: pubk}, type: "tinc", tinc: {file: mynode_file}}

candidate_node = {}
while candidate_node.nil? or candidate_node.empty? do
  begin
    ex.post_node(node) # publish own data to the server
  rescue => e
    p e
  end

  begin
    candidate_node = ex.get_random_node # fetch a random node
  rescue => e
    p e
  end
  sleep 1
end
t.import(candidate_node['tinc']['file'])
candnode_obj = Tinc.parse(candidate_node['tinc']['file'])
p candnode_obj

t.connect(candnode_obj['Name'],
          candidate_node['ip'],
          candidate_node['networks']['vpn'])
system({
  'SUBNET' => candidate_node['networks']['vpn']['subnet'].to_s,
  'NETWORK' => candidate_node['networks']['vpn']['network'],
  'BRIDGE_IP' => candidate_node['networks']['vpn']['assigned_ips'][0],
  'CONTAINER_IP' => candidate_node['networks']['vpn']['assigned_ips'][1],
  'PAIR_CONTAINER_IP' => candidate_node['networks']['vpn']['pair_container_ip'],
  'BRIDGE_IF' => "#{t.netname}br",
  'VPN_IF' => t.netname,
  'MASQ_IF' => config['tinc']['masqif']
}, "/usr/bin/env sh apsis-up.sh")

system(ENV.to_hash.merge({
  'ipexif' => t.netname,
  'ipexbr' => "#{t.netname}br",
  'gateway' => candidate_node['networks']['vpn']['gateway_ip'],
  'container_ipnet' => candidate_node['networks']['vpn']['assigned_ips'][1],
  'subnet' => candidate_node['networks']['vpn']['subnet'].to_s
}), config['dockerrunner']['command'] << ' ' << ARGV.join(' '))

system({
  'SUBNET' => candidate_node['networks']['vpn']['subnet'].to_s,
  'NETWORK' => candidate_node['networks']['vpn']['network'],
  'BRIDGE_IP' => candidate_node['networks']['vpn']['assigned_ips'][0],
  'CONTAINER_IP' => candidate_node['networks']['vpn']['assigned_ips'][1],
  'PAIR_CONTAINER_IP' => candidate_node['networks']['vpn']['pair_container_ip'],
  'BRIDGE_IF' => "#{t.netname}br",
  'VPN_IF' => t.netname,
  'MASQ_IF' => config['tinc']['masqif']
}, "/usr/bin/env sh apsis-down.sh")


