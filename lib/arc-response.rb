require 'rubygems'
require 'json'
require 'tempfile'

class ArcResponse
  attr_accessor  :columns, :first_iteration, :csv

  def initialize()
    @first_iteration = true
  end

  def arc_geom_type(geometry)
    result = 'point'

    if geometry.key? "paths"  then
      result = 'polyline'
    end

    if geometry.key? "rings" then
      result = "polygon"
    end

    if geometry.key? "points" then
      result = "multipoint"
    end

    if geometry.key? "xmin" then
      result = "envelop"
    end

    result
  end

  def create_multilinestring(geom)
    result = "MULTILINESTRING"
    result << get_points_ewkt(geom, "paths")
  end

  def create_multipoint(geom)
    result = "MULTIPOINT("
    points = []

    geom["points"].each{|point|
      ewkt = "(#{point[0]} #{point[1]})"
      points.push ewkt
    }

      result << points.join(',') << ")"
  end
 
  def create_polygon(geom)
    result = "POLYGON"
    result << get_points_ewkt(geom, "rings")
  end

  def create_temp_csv_file()
    @csv = Tempfile.open("arc-to-geoiq-csv")
    @csv.write(get_headers)
  end

  def get_column_names(data)
    @columns = data['fieldAliases'].keys.sort.push 'ewkt' 
  end

  def get_headers()
    headers = @columns.map { |item|
      "\"#{item}\""
    }
    headers.join(',') << "\n"
  end

  def get_points_ewkt(geom, key)
    point_strings = []

    geom[key].each{|line|
      ewkt = "("
      
      line.each{ |point|
        ewkt << "#{point[0]} #{point[1]},"
      }
      ewkt.sub!(/,$/,")")
      point_strings.push ewkt
    }


    result = "(#{point_strings.join(',')})"
  end


  def get_rows(data)
    rows = []
    data['features'].each { |arc_record|
        row = ''
      
      @columns.each{ |column|
        if column != "ewkt" then
          cleanedColumn = arc_record["attributes"][column].to_s.gsub('"', "'")
          row << "\"#{cleanedColumn}\","
        end
      }
      
      if arc_record['geometry'].nil? then
        raise RuntimeError.new('The layer lacks a geometry field')
      end

      row << "\"#{to_ewkt(arc_record["geometry"])}\"\n"
      rows.push row
    }
    rows.join
  end

  def handle_first_iteration(data)
      if @first_iteration then
        get_column_names data
        @first_iteration = false
        create_temp_csv_file
      end
  end

  def process_data(data)
    set = JSON.parse(data)
    handle_first_iteration set
    @csv.write(get_rows(set))
    @csv.flush
  end

  def to_ewkt(geom)
    result = ''
    case  arc_geom_type geom
      when  "point" 
        result = "POINT(#{geom["x"]} #{geom["y"]})"
      when "polyline"  
        result = create_multilinestring geom
      when "polygon" 
        result = create_polygon geom
      when "multipoint"
        result = create_multipoint geom
    end
    result
  end

end
