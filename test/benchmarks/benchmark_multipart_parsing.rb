# frozen_string_literal: true

require 'rack'
require 'minitest/autorun'
require 'minitest/benchmark'

class BenchmarkMultipartParsing < Minitest::Benchmark

  def self.bench_range
    bench_linear( 50, 500, 50 )
  end

  def bench_parser
    begin
      previous_limit = Rack::Utils.multipart_part_limit
      Rack::Utils.multipart_part_limit = 0

      requests = {}
      puts self.class.bench_range
      self.class.bench_range.each do |complexity|
        requests[complexity.to_s] = mock_request(complexity)
      end

      assert_performance_linear 0.99 do |complexity|
        Rack::Multipart.parse_multipart(requests[complexity.to_s])
      end
    ensure
      Rack::Utils.multipart_part_limit = previous_limit
    end
  end

  def mock_request(product_count)
    file = Rack::Multipart::UploadedFile.new(multipart_file("file1.txt"))
    params = { "file" => file }

    # One big sale, composed of many products
    params['sale[name]'] = "Test sale with #{product_count} products"

    product_count.times do |product_index|
      params["sale[product_attributes][#{product_index}][name]"] = "Product #{product_index}"

      # Each product has (say) 250 attributes
      250.times do |attr_index|
        params["sale[product_attributes][#{product_index}][attr-#{attr_index}]"] = "product attribute #{attr_index} value"
      end
    end

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
end