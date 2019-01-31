# Ward Poelmans <wpoely86@gmail.com> (Free University of Brussels)
#
# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# This plugin will convert a duration expressed in a timestamp to
# integer value in seconds/minutes/hours/days. The default is seconds
# For example: 02:04:03:01 => 187381 seconds
# Or: 120:0:0 => 432000 seconds
class LogStash::Filters::ToDuration < LogStash::Filters::Base

  # Example config to convert the 'durationfield' into seconds
  #
  # filter {
  #   toduration {
  #     fields => ["durationfield"]
  #     target => "seconds"
  #   }
  # }
  #
  config_name "toduration"

  # array of fields to convert
  config :fields, :validate => :array, :required => true
  # to what to convert to
  config :target, :validate => :string, :default => "seconds"

  # factors convert to durations
  CONVERSION = { "seconds" => 1, "minutes" => 60, "hours" => 3600, "days" => 86400}

  public
  def register
    if @target.nil? or !CONVERSION.has_key?(@target) then
        raise LogStash::ConfigurationError, "Invalid target field '#{@target}', expected one of '#{CONVERSION.keys.join(',')}'"
    end
  end # def register

  public
  def filter(event)
    @fields.each do |field|
      next unless event.include?(field)
      original = event.get(field)
      next unless !original.nil?
      if not original.is_a?(String) then
        @logger.info? && @logger.info("Message is not a string: #{original}")
        next
      end
      value = to_seconds(original)
      value = value / CONVERSION[@target]
      event.set(field, value)
    end

    filter_matched(event)
  end # def filter

  private
  # convert to seconds
  # @return duration in seconds (as float)
  def to_seconds(string)
    seconds = 0.0
    parts = string.split(':').reverse
    parts.each_index do |i|
        seconds += parts[i].to_f * CONVERSION.values[i]
    end

    return seconds
  end # def to_seconds

end # class LogStash::Filters::Duration
