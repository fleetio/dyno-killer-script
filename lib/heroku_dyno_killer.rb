require_relative 'papertrail/client'
require_relative 'heroku/client'
require 'platform-api'
require 'rest-client'

class HerokuDynoKiller
  def initialize(papertrail_config, heroku_config, threshold, load_threshold)
    @papertrail = PapertrailClient.new(papertrail_config)
    @heroku = HerokuClient.new(heroku_config)

    @threshold = threshold
    @load_threshold = load_threshold
  end

  # Restart all dynos that are over the threshold. Returns dynos that were
  # restarted.
  def restart_over_memory_threshold
    restarts = []

    dynos_over_memory_threshold.each do |dyno|
      @heroku.restart(dyno[:name])
      restarts.push dyno
    end

    restarts
  end

  def restart_over_load_threshold
    restarts = []

    dynos_over_load_threshold.each do |dyno|
      @heroku.restart(dyno[:name])
      restarts.push dyno
    end

    restarts
  end

  # Returns all dynos over threshold.
  def dynos_over_memory_threshold
    dynos_by_memory.select do |dyno|
      (dyno[:memory] == 'R14' ||
        dyno[:memory] >= @threshold) &&
        ((DateTime.now - DateTime.parse(dyno[:timestamp])).to_f * 24 * 60).to_i <= 6
    end
  end

  def dynos_over_load_threshold
    dynos_by_load.select do |dyno|
      dyno[:load] >= @load_threshold &&
        ((DateTime.now - DateTime.parse(dyno[:timestamp])).to_f * 24 * 60).to_i <= 6
    end
  end

  private

  # Get all dynos and their memory usage from papertrail logs.
  def dynos_by_memory
    data = {}
    @papertrail.events_with_memory_metrics.each do |event|
      data[dyno_name_from_event(event)] = [memory_from_event(event), event['received_at']]
    end

    data.map do |k, v|
      { name: k, memory: v[0], timestamp: v[1] }
    end
  end

  def dynos_by_load
    data = {}
    @papertrail.events_with_load_metrics.each do |event|
      data[dyno_name_from_event(event)] = [load_from_event(event), event['received_at']]
    end

    data.map do |k, v|
      { name: k, load: v[0], timestamp: v[1] }
    end
  end

  # Extract dyno name from log
  def dyno_name_from_event(event)
    event['program'].gsub('heroku/', '')
  end

  # Extract dyno memory from log
  def memory_from_event(event)
    if !event['message'].scan(/Error R14/).empty?
      'R14'
    else
      event['message'].scan(/sample#memory_total=(\d+\.\d*)/).last.first.to_f
    end
  end

  # Extract dyno load from log
  def load_from_event(event)
    event['message'].scan(/sample#load_avg_1m=(\d+\.\d*)/).last.first.to_f
  end
end
