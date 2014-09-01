require 'optparse'
require 'socket'
require 'webrick'
#require 'msgpack'
require 'resolv'
#require 'json'
require 'readline'

=begin
p Resolv::DNS.new.getaddresses(Socket::gethostname)
p Resolv.getaddresses(Socket::gethostname)
Resolv::DNS.new(:search => Socket::gethostname).each_address(Socket::gethostname) do |addr|
  p addr
end
=end

ipaddr = IPSocket::getaddress(Socket::gethostname).split('.').map! { |v| v.to_i }
rootpath = File.dirname(File.expand_path($0))

=begin
p ipaddr
p Socket::gethostname
p IPSocket::getaddress(Socket::gethostname)
=end
opts = {
  :document_root => rootpath,
  :log_root => Dir.pwd,
  :port => 6456,
}
OptionParser.new do |opt|
  opt.on('--document-root ROOT') { |pt| opts[:document_root] = pt }
  opt.on('--log-root ROOT') { |pt| opts[:log_root] = pt }
  opt.on('--port PORT') { |pt| opts[:port] = pt }
  opt.parse!(ARGV)
end

$stderr.printf("YOUR PIN is %03d\n", ipaddr[3])
$stderr.printf("DocumentRoot is \"#{opts[:document_root]}\"\n")

class Server

  def initialize(opts)
    @opts = opts
  end

  def start_server()
    @logger = WEBrick::Log.new(logname(@opts[:log_root]), WEBrick::BasicLog::DEBUG)
    @server_thread = Thread.new do
      config = {
        :DocumentRoot => "#{@opts[:document_root]}",
        :Port => @opts[:port],
        :Logger => @logger,
        #:AccessLog => [
        #  [logname(@opts[:log_root]), WEBrick::AccessLog::CLF],
        #],
      }
      @server = WEBrick::HTTPServer.new(config)
      @server.mount_proc('/api') do |req, res|
        queries = req.query_string.split('&')
        queries.each do |q|
          #p q
          case q
          when /\Aping/
            #p({ :result => 'ok' }.to_msgpack)
            #res.body = { 'result' => 'ok' }.to_msgpack
            res.body = 'ok'
          end
        end
        #p req.query_string
        #res.body = 'hoge'
      end
      trap('INT') { @server.shutdown }
      @server.start
    end
  end

  def logname(prefix)
    Time.now.strftime("#{prefix}/log-%Y%m%d-%H%M%S.log")
  end




  def proc()
    while buf = Readline.readline('> ', true)
      case buf
      when /^exit$/
        break
      end
      printf("#{buf}\n")
      trap('INT') { break }
    end
    @server_thread.join
  end


end

srv = Server.new(opts)
srv.start_server()
srv.proc()


