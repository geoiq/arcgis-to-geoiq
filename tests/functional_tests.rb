require 'rubygems'
require 'test/unit'
require 'shoulda'

require File.expand_path(File.dirname(__FILE__) + '/../lib/arc-to-geoiq')

class ArcToGeoIqFuncitonalTest < Test::Unit::TestCase

  def setup
    test_uri = "http://test.org/arcgis/rest/services/test/testlayers/MapServer/1/"
   @credentials = {
        :user => "test_arctogeoiq",
        :password => "testingentry",
        :uri => "http://geocommons.com"
   } 

    @atg = ArcToGeoiq.new(test_uri, @credentials, "functional testes")
  end


  should "raise exception when user is not provided" do
    values = get_values
    values[:credentials][:user] = ''

    assert_raise ArgumentError do
       @atg = ArcToGeoiq.new(values[:arc_uri], values[:credentials], "functional linestring tests")
    end
  end

  should "raise exception when password is not provided" do
    values = get_values
    values[:credentials][:password] = ''

    assert_raise ArgumentError do
       @atg = ArcToGeoiq.new(values[:arc_uri], values[:credentials], "functional linestring tests")
    end
  end

  should "raise exception when geoiq uri is not provided" do
    values = get_values
    values[:credentials][:uri] = ''

    assert_raise ArgumentError do
       @atg = ArcToGeoiq.new(values[:arc_uri], values[:credentials], "functional linestring tests")
    end
  end



  should "raise exception when arc uri is incorrect" do
    values = get_values

    #Typo in the uri: It should be MapServer, instead it is Mapserver
    values[:arc_uri] =  'http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/Mapserver/0' 

    assert_raise RuntimeError do
       @atg = ArcToGeoiq.new(values[:arc_uri], values[:credentials], "functional linestring tests")
       result = @atg.upload_to_geoiq
    end
  end 


  should "raise exception when it doesn't support ORDER BY queries" do
    values = get_values
    values[:arc_uri] = "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer/5"
   
    e = assert_raise(RuntimeError) {
       @atg = ArcToGeoiq.new(values[:arc_uri], values[:credentials], "functional linestring tests")
       result = @atg.upload_to_geoiq
    }
    assert_match(/Query clause not supported/i, e.message)  
  end


  should "raise exception when it doesn't support layer queries" do
    values = get_values
    values[:arc_uri] = "http://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Transportation/MapServer/0"
   
    e = assert_raise(RuntimeError) {
       @atg = ArcToGeoiq.new(values[:arc_uri], values[:credentials], "functional linestring tests")
       result = @atg.upload_to_geoiq
    }
    assert_match(/Layer doesn't support query/i, e.message)  
  end


  should "raise exception when geo uri is incorrect" do
    values = get_values
    values[:arc_uri] = "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/0"
    values[:credentials][:uri] =  'http://www.google.com' 
   
    assert_raise RuntimeError do
       @atg = ArcToGeoiq.new(values[:arc_uri], values[:credentials], "functional linestring tests")
       result = @atg.upload_to_geoiq
    end
  end 


#Example tests
  should "successfully load a linestring layer" do
    values = get_values
    values[:arc_uri] << "0"
     @atg = ArcToGeoiq.new(values[:arc_uri], @credentials, "functional linestring tests")
    result = @atg.upload_to_geoiq
    assert result
  end

  should "successfully load a polygon layer" do
    values = get_values
    values[:arc_uri] << "1"
     @atg = ArcToGeoiq.new(values[:arc_uri], @credentials, "functional polygon tests")
    result = @atg.upload_to_geoiq
    assert result
  end

  should "successfully load a point layer" do
    values = get_values
    values[:arc_uri] = "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/0"
     @atg = ArcToGeoiq.new(values[:arc_uri], @credentials, "functional points tests")
    result = @atg.upload_to_geoiq
    assert result
  end

  should "throw an exception saying that a data is bigger than the upload limit for GeoIq" do
    values = get_values
    values[:arc_uri] = "http://services.arcgisonline.com/ArcGIS/rest/services/Demographics/USA_Average_Household_Size/MapServer/3"
    
    e = assert_raise(RuntimeError) do
    @atg = ArcToGeoiq.new(values[:arc_uri], @credentials, "functional points tests")
    result = @atg.upload_to_geoiq
    end
    assert_match(/Size of data exceeds GeoIq upload limit/i, e.message) 
  end

#helper methods
 def get_values()
    values = {
      :credentials => {
        :user => "test_arctogeoiq",
        :password => "testingentry",
        :uri => "http://geocommons.com"
      },
      :arc_uri => "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StateCityHighway_USA/MapServer/" 
    }
    values
  end
end
