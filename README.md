This small project measures the multipart/form-data parsing performance of a few different versions of the rack gem.

In test/benchmarks/benchmark_multipart_parsing.rb you will find some benchmarking code which measures the time taken for the rack gem to parse a "sale" consisting of a number of "products". Each product consists of 250 attributes.

Look in the results folder for the results. My fork is much quicker.

To run the tests yourself, bundle install and then

```bundle exec ruby -Ilib:test test/benchmarks/benchmark_multipart_parsing.rb```
