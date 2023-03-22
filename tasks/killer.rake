namespace :dynos do
  task :list_over_memory_threshold do
    killer.dynos_over_memory_threshold.each do |dyno|
      if dyno[:memory] == 'R14'
        puts "Over threshold (#{ENV['MEMORY_THRESHOLD_IN_MB']}MB): " \
          "#{dyno[:name]} with #{dyno[:memory]} | Time: #{dyno[:timestamp]}"
      else
        difference = dyno[:memory] - ENV['MEMORY_THRESHOLD_IN_MB'].to_f
        puts "Over threshold (#{ENV['MEMORY_THRESHOLD_IN_MB']}MB): " \
          "#{dyno[:name]} with #{dyno[:memory]}MB " \
          "(#{difference.round}MB) | Time: #{dyno[:timestamp]}"
      end
    end
  end

  task :restart_over_memory_threshold do
    killer.restart_over_memory_threshold.each do |dyno|
      if dyno[:memory] == 'R14'
        puts "Restarting (#{ENV['MEMORY_THRESHOLD_IN_MB']}MB): #{dyno[:name]} "\
          "with #{dyno[:memory]} | Time: #{dyno[:timestamp]}"
      else
        difference = dyno[:memory] - ENV['MEMORY_THRESHOLD_IN_MB'].to_f
        puts "Restarting (#{ENV['MEMORY_THRESHOLD_IN_MB']}MB): " \
          "#{dyno[:name]} with #{dyno[:memory]}MB " \
          "(#{difference.round}MB) | Time: #{dyno[:timestamp]}"
      end
    end
  end

  task :list_over_load_threshold do
    killer.dynos_over_load_threshold.each do |dyno|
      difference = dyno[:load] - ENV['LOAD_1MIN_THRESHOLD'].to_f
      puts "Over load threshold (#{ENV['LOAD_1MIN_THRESHOLD']}): " \
        "#{dyno[:name]} with #{dyno[:load]} " \
        "(#{difference.round(2)}) | Time: #{dyno[:timestamp]}"
    end
  end

  task :restart_over_load_threshold do
    killer.restart_over_load_threshold.each do |dyno|
      difference = dyno[:load] - ENV['LOAD_1MIN_THRESHOLD'].to_f
      puts "Restarting (#{ENV['LOAD_1MIN_THRESHOLD']}): " \
        "#{dyno[:name]} with #{dyno[:load]} " \
        "(#{difference.round(2)}) | Time: #{dyno[:timestamp]}"
    end
  end

  task :restart_web do
    heroku = PlatformAPI.connect_oauth(ENV['HEROKU_TOKEN'])
    heroku.dyno.restart(ENV['APP_NAME'], 'web.')
  end

  private

  def killer
    @killer ||= HerokuDynoKiller.new(
      { app_name: ENV['APP_NAME'], token: ENV['HEROKU_TOKEN'] },
      ENV['MEMORY_THRESHOLD_IN_MB'].to_f,
      ENV['LOAD_1MIN_THRESHOLD'].to_f
    )
  end
end
