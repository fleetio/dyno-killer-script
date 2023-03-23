require_relative "datadog/client"
require_relative 'heroku/client'
require 'platform-api'
require 'rest-client'

class HerokuDynoKiller
  def initialize(heroku_config, threshold, load_threshold)
    @heroku = HerokuClient.new(heroku_config)
    @datadog = DatadogClient.new

    @threshold = threshold
    @load_threshold = load_threshold
  end

  # Restart all dynos that are over the threshold. Returns dynos that were
  # restarted.
  def restart_over_memory_threshold
    restarts = []

    dynos_over_memory_threshold.each do |dyno|
      @heroku.restart(dyno[:name])
      @datadog.send_event(
        "Restarting (#{ENV['MEMORY_THRESHOLD_IN_MB']}MB): #{dyno[:name]} "\
          "with #{dyno[:memory]} | Time: #{dyno[:timestamp]}",
        "",
        [
          "event_type:restart",
          "env:production"
        ]
      )
      restarts.push dyno
    end

    restarts
  end

  def restart_over_load_threshold
    restarts = []

    dynos_over_load_threshold.each do |dyno|
      @heroku.restart(dyno[:name])
      @datadog.send_event(
        "Restarting (#{ENV['LOAD_1MIN_THRESHOLD']}): " \
          "#{dyno[:name]} with #{dyno[:load]} | Time: #{dyno[:timestamp]}",
        "",
        [
          "event_type:restart",
          "env:production"
        ]
      )
      restarts.push dyno
    end

    restarts
  end

  # Returns all dynos over threshold.
  def dynos_over_memory_threshold
    dynos_by_memory.select do |dyno|
      (dyno[:memory] == 'R14' ||
        dyno[:memory] >= @threshold) &&
        (Time.now.utc - dyno[:timestamp]).to_f / 60 <= 6
    end
  end

  def dynos_over_load_threshold
    dynos_by_load.select do |dyno|
      dyno[:load] >= @load_threshold &&
        (Time.now.utc - dyno[:timestamp]).to_f / 60 <= 6
    end
  end

  private

  # Get all dynos and their memory usage from logs.
  def dynos_by_memory
    data = {}
    @datadog.events_with_memory_metrics(@threshold).each do |event|
      data[dyno_name_from_event(event)] = [memory_from_event(event), event.timestamp]
    end

    data.map do |k, v|
      { name: k, memory: v[0], timestamp: v[1] }
    end
  end

  def dynos_by_load
    data = {}
    @datadog.events_with_load_metrics(@load_threshold).each do |event|
      data[dyno_name_from_event(event)] = [load_from_event(event), event.timestamp]
    end

    data.map do |k, v|
      { name: k, load: v[0], timestamp: v[1] }
    end
  end

  # Extract dyno name from log
  def dyno_name_from_event(event)
    event.attributes["syslog"][:procid]
  end

  # Extract dyno memory from log
  def memory_from_event(event)
    if event.attributes.dig("error", :kind)
      "R14"
    else
      event.attributes.dig("heroku", :memory, :total).to_f / 1_000_000
    end
  end

  # Extract dyno load from log
  def load_from_event(event)
    event.attributes.dig("heroku", :cpu, :"1m").to_f
  end
end
