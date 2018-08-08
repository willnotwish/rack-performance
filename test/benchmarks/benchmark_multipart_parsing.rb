# frozen_string_literal: true

require 'rack'
require 'minitest/autorun'
require 'minitest/benchmark'

class BenchmarkMultipartParsing < Minitest::Benchmark

  def bench_parser
    # Build and cache the requests before we start testing
    requests = self.class.bench_range.reduce({}) do |hash, product_count|
      hash[product_count.to_s] = build_request(product_count)
      hash
    end

    # Now the test: that the time taken is directly proportional
    # to the number of products
    assert_performance_linear 0.99 do |product_count|
      Rack::Multipart.parse_multipart(requests[product_count.to_s])
    end
  end

  private

  def self.bench_range
    bench_linear( 50, 500, 50 ) # 50, 100, 150 ... 500
  end

  def build_request(product_count)
    # One big sale, composed of many products
    params = product_count.times.reduce({}) do |hash, product_index|
      # Each product has 250 nested attributes
      nested_attrs = 250.times.reduce({}) do |attrs, index|
        key = "sale[product_attributes][#{product_index}][attr-#{index}]"
        attrs[key] = "product attribute #{index} value"
        attrs
      end
      hash.merge nested_attrs
    end
    # Need at least one uploaded file otherwise the encoding
    # won't be multipart/form-data
    params['file'] = Rack::Multipart::UploadedFile.new(multipart_file("file1.txt"))

    data  = Rack::Multipart.build_multipart(params)
    options = {
      "CONTENT_TYPE" => "multipart/form-data; boundary=AaB03x",
      "CONTENT_LENGTH" => data.length.to_s,
      :input => StringIO.new(data)
    }
    Rack::MockRequest.env_for("/", options)
  end

  def multipart_file(name)
    File.join(File.dirname(__FILE__), "..", "multipart", name.to_s)
  end

  # Need to override the multipart limit
  def setup
    @previous_limit = Rack::Utils.multipart_part_limit
    Rack::Utils.multipart_part_limit = 0
  end

  def teardown
    Rack::Utils.multipart_part_limit = @previous_limit
  end
end