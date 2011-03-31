require 'rubygems'
require 'test/unit'
require 'shoulda'

require File.expand_path(File.dirname(__FILE__) + '/../lib/arc-to-geoiq')

class ArcToGeoiqTest < Test::Unit::TestCase

  def setup
    test_uri = "http://test.org/arcgis/rest/services/test/testlayers/MapServer/1/"
   @credentials = {
        :user => "test_arctogeoiq",
        :password => "testingentry",
        :uri => "http://geocommons.com"
   } 

    @atg = ArcToGeoiq.new(test_uri, @credentials, "unit testes")
  end

  should "strip backlash from uri at construction" do
    test_uri = "http://test.org/"
    @atg = ArcToGeoiq.new(test_uri, @credentials, "unit tests")
    assert_equal "http://test.org", @atg.uri   
  end

  should "add metadata layer " do
    test_uri = "http://test.org/layers/1"
    result = @atg.get_meta_query test_uri
    assert_equal "http://test.org/layers/1?f=json", result 
  end

  should "add query to retrive all" do
    test_uri = "http://test.org"
    id_column = "OBJECTID"
    result = @atg.get_data_query test_uri, "OBJECTID", 1
    assert_equal "http://test.org/query?where=\"OBJECTID\"+>+1&outFields=*&outSR=4326&f=json", result 
  end

  should "add the title for the data layer" do
    test_uri = "http://test.org/"
    result = @atg.add_parameter test_uri, "title", "my dataset"
    assert_equal "http://test.org/&title=my%20dataset", result
  end

  should "add the citation url" do
    test_uri = "http://test.org/"
    citation_uri = "http://testarc.org"
    result = @atg.add_parameter test_uri, "citation_url", citation_uri 
    assert_equal "http://test.org/&citation_url=http://testarc.org", result
  end

end
