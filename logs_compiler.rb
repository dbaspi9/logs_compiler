class LogsCompiler
  require 'open-uri'
  require 'nokogiri'
  require 'net/ftp'
  require 'yaml'
  require 'json'

  def initialize
    @secrets = YAML.load_file('secrets.yml')
    @varnish_logs = File.readlines('varnish.log')
    download_xml_data
    @xml_logs = Nokogiri::XML(File.read('data.xml'))
    download_json_data
    @json_logs = JSON.parse(File.read('data.json'))
  end

  def print_varnish_logs
    puts "Varnish logs\n\n"
    @a = { 'hosts' => {}, 'paths' => {} }
    compiled_logs = @varnish_logs.map do |record|
      records_with_http = record.split(' ').select{ |x| x.include?('http://') }
      path = records_with_http[0]
      host = records_with_http[1]
      @a['hosts'][host] = @a['hosts'][host].nil? ? 1 : @a['hosts'][host] + 1
      @a['paths'][path] = @a['paths'][path].nil? ? 1 : @a['paths'][path] + 1
    end
    @most_charged_hosts = @a['hosts'].sort { |a1,a2| a2[1] <=> a1[1] }.first(5)
    @most_requested_files = @a['paths'].sort { |a1,a2| a2[1] <=> a1[1] }.first(5)
    puts "Hosts with the most traffic: #{@most_charged_hosts}\n"
    puts "Files with the most requests: #{@most_requested_files}\n"
  end

  def print_xml_logs
    puts "\nXML logs\n\n"

    @xml_logs.xpath("//item").to_a.sort_by { |x| x.xpath('g:price').text.to_f }.reverse.map do |node|
      puts "#{node.xpath('g:price').text}\n #{node.xpath('title').text}\n #{node.xpath('link').text}\n\n"
    end
  end

  def print_json_logs
    puts "\nJSON logs\n\n"
    @json_logs.sort_by { |v| v['price'].to_f }.reverse.map do |record|
      puts "#{record['price']}\n #{record['title']}\n #{record['full_url']}\n\n"
    end
  end

  private

  def download_xml_data
    File.write 'data.xml', open('https://feeds.datafeedwatch.com/8946/87b1895fcf293e81cc27af931aa0c3c6d6b580d6.xml').read
  end

  def download_json_data
    ftp = Net::FTP.new(@secrets['ftp_host'])
    ftp.login(@secrets['ftp_user'], @secrets['ftp_password'])
    ftp.passive = true
    ftp.getbinaryfile('feed.json', 'data.json', 1024)
    ftp.close
  end
end
