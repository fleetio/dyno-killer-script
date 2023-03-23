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

  def send_event(title, text, tags = [])
    body = DatadogAPIClient::V1::EventCreateRequest.new({
      title: title,
      text: text,
      tags: tags
    })

    events_api_client.create_event(body)
  end

  private

  def request(search_term)
    body = DatadogAPIClient::V2::LogsListRequest.new({
      filter: DatadogAPIClient::V2::LogsQueryFilter.new({
        query: search_term,
        from: "now-10m",
        to: "now"
      }),
      sort: DatadogAPIClient::V2::LogsSort::TIMESTAMP_ASCENDING,
      page: DatadogAPIClient::V2::LogsListRequestPage.new({
        limit: 1000
      })
    })
    opts = {
      body: body
    }
    logs = logs_api_client.list_logs(opts)
    logs.data.map(&:attributes)
  end

  def logs_api_client
    @logs_api_client ||= DatadogAPIClient::V2::LogsAPI.new
  end

  def events_api_client
    @events_api_client ||= DatadogAPIClient::V1::EventsAPI.new
  end
end
