require "datadog_api_client"

DatadogAPIClient.configure do |config|
  config.api_key = ENV["DD_API_KEY"]
  config.application_key = ENV["DD_APP_KEY"]
end

class DatadogClient
  # Read all logs that that output memory
  def events_with_memory_metrics(threshold_in_mb)
    threshold = threshold_in_mb * 1_000_000
    request("(@heroku.memory.total:>#{threshold} (dyno:web* OR dyno:sidekiq*)) OR @error.kind:R14")
  end

  def events_with_load_metrics(threshold)
    request("dyno:web* @heroku.cpu.1m:>#{threshold}")
  end

  private

  def request(search_term)
    api_instance = DatadogAPIClient::V2::LogsAPI.new
    body = DatadogAPIClient::V2::LogsListRequest.new({
      filter: DatadogAPIClient::V2::LogsQueryFilter.new({
        query: search_term,
        from: "now-10m",
        to: "now",
      }),
      sort: DatadogAPIClient::V2::LogsSort::TIMESTAMP_ASCENDING,
      page: DatadogAPIClient::V2::LogsListRequestPage.new({
        limit: 1000,
      }),
    })
    opts = {
      body: body,
    }
    logs = api_instance.list_logs(opts)
    logs.data.map(&:attributes)
  end
end
