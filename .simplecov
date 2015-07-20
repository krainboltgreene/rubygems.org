# https://github.com/colszowka/simplecov#using-simplecov-for-centralized-config
# see https://github.com/colszowka/simplecov/blob/master/lib/simplecov/defaults.rb
# vim: set ft=ruby
@minimum_coverage = ENV.fetch('COVERAGE_MINIMUM') { 91.6 }.to_f.round(2)
# rubocop:disable Style/DoubleNegation
ENV['FULL_BUILD'] ||= ENV['CI']
@running_ci       = !!(ENV['FULL_BUILD'] =~ /\Atrue\z/i)
@generate_report  = @running_ci || !!(ENV['COVERAGE'] =~ /\Atrue\z/i)
# rubocop:enable Style/DoubleNegation

SimpleCov.profiles.define 'rubygems' do
  coverage_dir 'reports/coverage'
  load_profile 'test_frameworks'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Libraries', 'lib'
  add_group 'Middlewares', 'app/middleware'
  add_group 'Jobs', 'app/jobs'
  add_group 'API', 'app/controllers/api'

  add_group 'Long files' do |src_file|
    src_file.lines.count > 100
  end
  class MaxLinesFilter < SimpleCov::Filter
    def matches?(source_file)
      source_file.lines.count < filter_argument
    end
  end
  add_group 'Short files', MaxLinesFilter.new(5)

  # Exclude these paths from analysis
  add_filter '/config/'
  add_filter '/db/'
  add_filter 'tasks'
end

## START TRACKING COVERAGE
require 'coverage'
Coverage.start

# rubocop:disable Style/MultilineBlockChain
RubyGemsCoverage = Class.new do
  def initialize(&block)
    @block = block
  end

  def start
    @block.call
  end
end.new do
  SimpleCov.start 'rubygems'
  if @generate_report
    STDERR.puts '[COVERAGE] Running with SimpleCov HTML Formatter'
    formatters = [SimpleCov::Formatter::HTMLFormatter]
  else
    formatters = []
  end
  if @running_ci
    require 'codeclimate-test-reporter'
    STDERR.puts '[COVERAGE] Running with CodeClimate TestReporter Formatter'
    formatters << CodeClimate::TestReporter::Formatter
  end
  SimpleCov.formatters = formatters
end
# rubocop:enable Style/MultilineBlockChain
SimpleCov.at_exit do
  SimpleCov.result.format!
  percent = Float(SimpleCov.result.covered_percent)
  if percent < @minimum_coverage
    STDERR.puts "Spec coverage was not high enough: "\
    "#{percent.round(2)} is < #{@minimum_coverage}%"
    exit 1 if @generate_report
  else
    STDERR.puts "Nice job! Spec coverage (#{percent.round(2)}) "\
    "is still at or above #{@minimum_coverage}%"
  end
end
