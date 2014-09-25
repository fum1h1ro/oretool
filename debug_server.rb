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

addr = nil
Socket::ip_address_list.each do |adrs|
  if adrs.ipv4? and adrs.ipv4_private?
    addr = adrs
  end
end
ipaddr = addr.inspect_sockaddr.split('.').map! { |v| v.to_i }
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
        :AccessLog => [
          [@logger, WEBrick::AccessLog::CLF],
        ],
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
      #trap('INT') { p self; @server.shutdown }
      @server.start
    end
  end

  def logname(prefix)
    Time.now.strftime("#{prefix}/log-%Y%m%d-%H%M%S.log")
  end




  def proc()
    stty_save = `stty -g`.chomp
    trap('INT') { @server.shutdown; system "stty", stty_save; exit }
    begin
      while buf = Readline.readline('> ', true)
        case buf
        when /^exit$/
          break
        when /^help$/
          print_help
        else
          system("rake ${buf}")
          printf("#{buf}\n")
        end
      end
    rescue Interrupt
      system("stty", stty_save)
    end
    @server.shutdown
    #@server_thread.join
  end

  def print_help
    print 'help'
  end
end

srv = Server.new(opts)
srv.start_server()
srv.proc()


