require 'rubygems'
require 'optparse'
require 'ostruct'

require 'lib/arc-to-geoiq'

#Command line utility to exercise the arc-to-geoiq library
class Arc2GeoIqOptions

  def self.parse(args)
    options = {
      :arc_uri => "",
      :geoiq_uri => "http://geocommons.com",
      :user => "",
      :password => "",
      :dump => false
    }



    opts = OptionParser.new do |opts|
      opts.banner = "Usage: arc2geoiq.rb -a <arc layer uri> -g <geoiq server uri> -u <geoiq user> -p<geoiq password>"
      opts.on("-a", "--arc-uri ARCURI", String, "ArcGIS REST Server layer uri") do |uri|
        options[:arc_uri] = uri
      end

      opts.on("-d", "--dump-csv", "It will dump a copy of the csv created from the arc server. It will not upload to GeoIq.") do
        options[:dump] = true
      end

      opts.on("-g", "--geoiq-server GEOIQURI", String,  "GeoIq Server. It defaults to http://geocommons.com") do |geoiq_uri|
        options[:geoiq_uri] = geoiq_uri
      end

      opts.on("-u", "--user USER", String, "GeoIQ user name") do |user|
        options[:user] = user
      end

      opts.on("-p", "--password PASSWORD", String, "GeoIq password") do |password|
        options[:password] = password
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

    end

    opts.parse!(args)
    options
  end
end

#The script proper
class ArcToGeoIqUtil

  def upload(args)
    options = Arc2GeoIqOptions.parse(args)
    uri = options[:arc_uri]

    geo_credentials = {
      :uri => options[:geoiq_uri],
      :user => options[:user],
      :password => options[:password]
    }

    begin
      a2g = ArcToGeoiq.new(uri, geo_credentials)

      if options[:dump] then
        a2g.verbose = false
        a2g.dump_csv
      else
        a2g.upload_to_geoiq
      end

    rescue ArgumentError => e
      puts "Credential problem. #{e.message}"
      #raise e
    rescue RuntimeError => e
      case e.message
      when "The layer lacks a geometry field"
        puts "The requested layer lacks a geometry field"
      when "Query clause not supported"
        puts "The layer that you requested doesn't suppor the necessary query statement for getting all of the data."
      when "Layer doesn't support query"
        puts "The layer that you requested doesn't allow query operations."
      when "Size of data exceeds GeoIq upload limit."
        puts "The layer that you requested exceeds GeoIq's file size limit"
      else
        puts "There was en error with your request. Details: #{e.message}"
      end
      #raise e
    rescue Exception => e
      puts "There was en error with your request. Details: #{e.message}"
      #raise e
    end
  end
end

if __FILE__ == $0
  util = ArcToGeoIqUtil.new()
  util.upload(ARGV)
end

