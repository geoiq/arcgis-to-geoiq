require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'json'

require File.expand_path(File.dirname(__FILE__) + '/../lib/arc-response')

class ArcResponseTest < Test::Unit::TestCase
  attr_accessor :response


 
 #change
  should "get columns from response object, short" do
    single_point_setup  
   
    @response.get_column_names JSON.parse(@data)
    headers = @response.get_headers
    
    assert_equal "\"CITY_NAME\",\"ewkt\"\n", headers
  end

  #change
  should "get rows from response objects" do
    single_point_setup
    
    @response.get_column_names JSON.parse(@data)
    row = @response.get_rows JSON.parse(@data)
    
    assert_equal "\"Oswego\",\"POINT(-76.5026008059999 43.4584576990001)\"\n", row
  end

  should "transform a arcGeometry point to a WKT point" do
    single_point_setup
    geometry = {
      "x" => -76.5026008059999,
      "y" => 43.4584576990001 
    }
    
    result = @response.to_ewkt geometry

    assert_equal "POINT(-76.5026008059999 43.4584576990001)", result
  end

  should "transform an arcGeometry polyline to a WKT multiline string" do
    single_point_setup
    geometry = {
      "paths" => [
        [ [-97.06138,32.837], [-97.06133,32.836], [-97.06124,32.834], [-97.06127,32.832] ], 
        [ [-97.06326,32.759], [-97.06298,32.755] ]
      ],
      "spatialReference" => {"wkid" => 4326}
    }

    result = @response.to_ewkt geometry

    assert_equal "MULTILINESTRING((-97.06138 32.837,-97.06133 32.836,-97.06124 32.834,-97.06127 32.832),(-97.06326 32.759,-97.06298 32.755))", result
  end

  should "identify if a geometry is ArcGeometry Point type" do
    single_point_setup
    geometry = {
      "x" => -76.5026008059999,
      "y" => 43.4584576990001 
    }

    type = @response.arc_geom_type geometry
    assert_equal  'point', type

  end

  should "identify if a geometry is ArcGeometry Polyline type" do
    single_point_setup
    geometry = {
      "paths" => [
        [ [-97.06138,32.837], [-97.06133,32.836], [-97.06124,32.834], [-97.06127,32.832] ], 
        [ [-97.06326,32.759], [-97.06298,32.755] ]
      ],
      "spatialReference" => {"wkid" => 4326}
    }

    type = @response.arc_geom_type geometry
    assert_equal  'polyline', type
  end


  should "identify if a geometry is ArcGeometry Polygon type" do
    single_point_setup
    geometry = {
      "rings" => [ 
        [ [-97.06138,32.837], [-97.06133,32.836], [-97.06124,32.834], [-97.06127,32.832], [-97.06138,32.837] ], 
        [ [-97.06326,32.759], [-97.06298,32.755], [-97.06153,32.749], [-97.06326,32.759] ]
      ],
"spatialReference" => {"wkid" => 4326}

    }

    type = @response.arc_geom_type geometry
    assert_equal  'polygon', type
  end


  should "identify if a geometry is ArcGeomtry Multipoint type" do
    single_point_setup
    geometry = {
      "points" => [ [-97.06138,32.837], [-97.06133,32.836], [-97.06124,32.834], [-97.06127,32.832] ],
      "spatialReference" => {"wkid" => 4326}
    }  
    

    type = @response.arc_geom_type geometry
    assert_equal  'multipoint', type
  end

  should "identify if a geometry is ArcGeomtry Envelop type" do
    single_point_setup
    geometry = {
      "xmin" => -109.55, 
      "ymin" => 25.76, 
      "xmax" => -86.39, 
      "ymax" => 49.94,
      "spatialReference" => {"wkid" => 4326}
   }  
    

    type = @response.arc_geom_type geometry
    assert_equal  'envelop', type
  end

  should "transform an arcGeometry polygone to a WKT polygon string" do
    single_point_setup
    geometry = {
       "rings" => [ 
        [ [-97.06138,32.837], [-97.06133,32.836], [-97.06124,32.834], [-97.06127,32.832], [-97.06138,32.837] ], 
        [ [-97.06326,32.759], [-97.06298,32.755], [-97.06153,32.749], [-97.06326,32.759] ]
      ],

      "spatialReference" => {"wkid" => 4326}    
    }

    result = @response.to_ewkt geometry

    assert_equal "POLYGON((-97.06138 32.837,-97.06133 32.836,-97.06124 32.834,-97.06127 32.832,-97.06138 32.837),(-97.06326 32.759,-97.06298 32.755,-97.06153 32.749,-97.06326 32.759))", result
  end

  should "transform an arcGeometry Multipoint to a WKT multipoint" do
    single_point_setup
    geometry = {
      "points" => [ [-97.06138,32.837], [-97.06133,32.836], [-97.06124,32.834], [-97.06127,32.832] ],
      "spatialReference" => {"wkid" => 4326}
    }  
    
    result = @response.to_ewkt geometry
    assert_equal  "MULTIPOINT((-97.06138 32.837),(-97.06133 32.836),(-97.06124 32.834),(-97.06127 32.832))", result
  end



# helping methods
  def single_point_setup()
    @data = '{"displayFieldName":"CITY_NAME","fieldAliases":{"CITY_NAME":"CITY_NAME"},"geometryType":"esriGeometryPoint","spatialReference":{"wkid":4326},"features":[{"attributes":{"CITY_NAME":"Oswego"},"geometry":{"x":-76.5026008059999,"y":43.4584576990001}}]}'

    @response = ArcResponse.new()
  end

end
