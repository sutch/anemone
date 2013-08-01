$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

# Based on Anemone::Page (i.e., only tests HTML resources)

module Anemone
  describe Resource do

    before(:each) do
      FakeWeb.clean_registry
      @http = Anemone::HTTP.new(:page_class => Anemone::Page)

      @page = @http.fetch_page(FakePage.new('home', :links => '1').url)
    end

    describe "#to_hash" do
      it "converts the page to a hash" do
        hash = @page.to_hash
        hash['url'].should == @page.url.to_s
        hash['referer'].should == @page.referer.to_s
        hash['links'].should == @page.links.map(&:to_s)
      end
    end

    describe "#from_hash" do
      it "converts from a hash to a Page" do
        page = @page.dup
        page.depth = 1
        converted = Page.from_hash(page.to_hash)
        converted.links.should == page.links
        converted.depth.should == page.depth
      end
    end

    describe "#links" do
      it "should not convert anchors to %23" do
        page = @http.fetch_page(FakePage.new('', :body => '<a href="#top">Top</a>').url)
        page.links.should have(1).link
        page.links.first.to_s.should == SPEC_DOMAIN
      end
    end

    it "should detect, store and expose the base url for the page head" do
      base = "#{SPEC_DOMAIN}path/to/base_url/"
      page = @http.fetch_page(FakePage.new('body_test', {:base => base}).url)
      page.base.should == URI(base)
      @page.base.should be_nil
    end

    it "should have a method to convert a relative url to an absolute one" do
      @page.should respond_to(:to_absolute)

      # Identity
      @page.to_absolute(@page.url).should == @page.url
      @page.to_absolute("").should == @page.url

      # Root-ness
      @page.to_absolute("/").should == URI("#{SPEC_DOMAIN}")

      # Relativeness
      relative_path = "a/relative/path"
      @page.to_absolute(relative_path).should == URI("#{SPEC_DOMAIN}#{relative_path}")

      deep_page = @http.fetch_page(FakePage.new('home/deep', :links => '1').url)
      upward_relative_path = "../a/relative/path"
      deep_page.to_absolute(upward_relative_path).should == URI("#{SPEC_DOMAIN}#{relative_path}")

      # The base URL case
      base_path = "path/to/base_url/"
      base = "#{SPEC_DOMAIN}#{base_path}"
      page = @http.fetch_page(FakePage.new('home', {:base => base}).url)

      # Identity
      page.to_absolute(page.url).should == page.url
      # It should revert to the base url
      page.to_absolute("").should_not == page.url

      # Root-ness
      page.to_absolute("/").should == URI("#{SPEC_DOMAIN}")

      # Relativeness
      relative_path = "a/relative/path"
      page.to_absolute(relative_path).should == URI("#{base}#{relative_path}")

      upward_relative_path = "../a/relative/path"
      upward_base = "#{SPEC_DOMAIN}path/to/"
      page.to_absolute(upward_relative_path).should == URI("#{upward_base}#{relative_path}")
    end

  end
end
