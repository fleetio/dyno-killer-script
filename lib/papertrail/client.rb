class PapertrailClient
  def initialize(config)
    @token = config[:token]
  end

  # Read all logs that that output memory
  def events_with_memory_metrics
    request('heroku%2Fweb+sample%23memory_total%3D+OR+"error+r14"')
  end

  def events_with_load_metrics
    request('heroku%2Fweb+sample%23load_avg_1m%3D')
  end

  private

  def request(search_term)
    response = RestClient.get(
      "https://papertrailapp.com/api/v1/events/search.json?q=#{search_term}",
      { 'X-Papertrail-Token' => @token }
    )
    data = JSON.parse(response.to_str)
    data['events']
  end
end
