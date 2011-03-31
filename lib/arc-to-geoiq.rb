require 'rubygems'
require 'net/http'
require 'json'
require 'ftools'


require File.expand_path(File.dirname(__FILE__) + '/arc-response')

class ArcToGeoiq
  attr_accessor :data, :meta, :response, :uri, :arc_response, :title 
  attr_accessor :id_column, :verbose, :limit 
  attr_accessor :geoiq_uri, :geoiq_user, :geoiq_password
 
  GEOIQ_UPLOAD_LIMIT = 7000000

  def initialize(uri = nil, geoiq_credentials = {}, title = "arc-to-geoiq layer", arc_response = nil)

    @uri = strip_uri_final_slash uri
    @title = title
    set_geoiq_credentials geoiq_credentials

    if arc_response == nil
      @arc_response = ArcResponse.new 
    else
      @arc_response = json_response
    end

    @data = []
    @verbose = true
    @limit = true
  end

  def add_parameter(uri, parameter, value)
    if parameter == "title" && value != "" then
     result =  "#{uri}&#{parameter}=#{URI.escape(value)}"
    else
      result =  "#{uri}&#{parameter}=#{value}"
    end
  end

  def check_credentials(credentials)
    values = [:user, :uri, :password]

    values.each { |value|
      if credentials[value].nil? || credentials[value] == '' then
        raise  ArgumentError.new("GeoIQ credentials value missing: #{value}")
      end
    }
  end

  def dump_csv()
    @limit = false
    path = get_csv
    File.copy(path, "./output.csv")
  end

  def examine_problem(data)
    if !data['error'].nil? then
      if !data['error']['details'].nil? then
        case data['error']['details'][0] 
          when 'Unable to perform query. Please check your parameters.'
            raise RuntimeError.new("Query clause not supported")
          when 'Query operation not supported on this service'
            raise RuntimeError.new("Layer doesn't support query")
          else
            raiase RuntimeError.new("Problem reaching the ArcGIS server. Details #{data['error']['details']}")
        end
      end
    end
  end

  def get_csv()
    get_data
    @arc_response.csv.path
  end

  def get_data
    get_meta
    last_record_id = 0 
    finished = false
   
    until finished
      resource = get_data_query @uri, @id_column, last_record_id      
      if @verbose then
        puts resource
      end
      
      get resource
      examine_data = JSON.parse(@response.body)
 
      if last_record_id == 0 && examine_data['features'].nil? then
        examine_problem examine_data
        raise RuntimeError.new("ArcToGeoIq problem with results. Is your Uri to Arc server correct?")
      end

      @arc_response.process_data @response.body
      
      record_number = examine_data['features'].length
      
      if record_number != 0 then
        last_record_id = examine_data['features'][record_number - 1]['attributes'][@id_column]
      end

      if record_number < 500 then
        finished = true
      end

      if @limit && @arc_response.csv.size >= GEOIQ_UPLOAD_LIMIT then
        raise RuntimeError.new("Size of data exceeds GeoIq upload limit.")
      end
    end
  end

  def get_data_query(uri, id_column, last_record)
    result = "#{uri}/query?where=\"#{id_column}\"+>+#{last_record}&outFields=*&outSR=4326&f=json"
  end

  def get_id_column(fields)
    result = ""
    fields.each { |field|
      if field['type'] == "esriFieldTypeOID" then
        result = field["name"]
      end
    }
    if result == "" then
      raise RuntimeError.new("Couldn't find the ID field")
    end
    result
  end

  def get_meta
    resource = get_meta_query @uri

    get resource
    @meta = JSON.parse @response.body

    if @meta['fields'].nil? then
      raise RuntimeError.new("ArcToGeoIq error. Retrieving metadata for arc layer failed.")
    end
    set_meta_columns
  end

  def get_meta_query(uri)
    result = "#{uri}?f=json"
  end

  def get(resource)
    begin
      @response = Net::HTTP.get_response(URI.parse(URI.encode(resource)))
    rescue Exception => e
      message = "ArcToGeoIq error while retriving resource #{resource}: " 
      message << e.message
      raise RuntimeError.new(message)
    end
  end

  def meta_to_geoiq_meta()
    result = {}
    result['title'] = @meta['name']
    result['source'] = @uri
    result['citation_url'] = @uri
    result['description'] = @meta['copyrightText']

    result = Json.generate(result)
  end

  def post_to_geoiq(path)
    resource = prepare_resource
    uri = URI.parse(resource)

    http = Net::HTTP.new(uri.host, uri.port)
    headers = {"Content-Type" => "text/csv"}
    request = Net::HTTP::Post.new(uri.request_uri, headers)
  
    request.basic_auth @geoiq_user, @geoiq_password
    request.body = File.read(path)

    begin 
      response = http.request(request)
      
      if @verbose then
        puts "GeoIq Status Code: #{response.code}"
      end
      
      if response.code.to_i >= 400 then
        message = "ArcToGeoIq error. Problem with GeoIq status code: #{response.code}"
        raise RuntimeError.new(message)
      end

    rescue Exception => e
      message = "ArcToGeoIq error while uploading to GeoIq resource #{resource}: " 
      message << e.message
      message << " Info: #{response.code} #{response.body}"
      raise message
    end
    if @verbose then
      puts "Arc layer: #{resource}"
      puts "GeoIq dataset: #{response['location']}"
    end
    response['location']
  end

  def prepare_resource()
    resource = "#{@geoiq_uri}/datasets.json"
    
   resource = add_parameter resource << "?", "title", @title
   resource = add_parameter resource, "citation_url", @uri
   resource = add_parameter resource, "metadata_url", @uri
  end
  
  def put_metadata(metadata, uri)
    body = meta_to_geoiq_meta
    # Similar to post_to_geoiq once implemented
  end

  def set_geoiq_credentials(credentials)
    check_credentials credentials
    @geoiq_uri = credentials[:uri]
    @geoiq_user =  credentials[:user]
    @geoiq_password = credentials[:password]
  end

  def set_meta_columns()
    @title =  @meta['name']
    @id_column = get_id_column @meta['fields']
  end

  def strip_uri_final_slash(uri)
    if  uri =~ /\/$/ then
      uri.sub!(/\/$/, "")
    end

    return uri
  end

  def update_metadata(uri)
    get_meta
    put_medadata uri 
  end

  def upload_to_geoiq()
    #swith to file upload method
    path = get_csv
    dataset_uri = post_to_geoiq path
    
    if not dataset_uri.nil? && dataset_uri != "" then
      true
    else
      false
    end
  end

end

