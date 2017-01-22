require 'jwt'
require 'rest-client'

class Exchanger
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


