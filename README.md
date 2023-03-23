# Fleetio Dyno Killer
Utility to restart `web` dynos on heroku that are exceed a certain metric threshold. Currently supported metrics are:
* Memory
* 1 Minute Load Average

It relies on [heroku's log-runtime-metrics](https://devcenter.heroku.com/articles/log-runtime-metrics) for the data and uses heroku's PlatformAPI gem to actually restart the dynos.

It is currently running on heroku, https://dashboard.heroku.com/apps/fleetio-dyno-killer


## Usage
1. Setup your env file with the following variables:
```
APP_NAME
HEROKU_TOKEN
LOAD_1MIN_THRESHOLD
MEMORY_THRESHOLD_IN_MB
DD_API_KEY
DD_APP_KEY
```

2. Run one of the four rake tasks
```
[heroku run || dotenv] rake:dynos:list_over_memory_threshold
[heroku run || dotenv] rake:dynos:restart_over_memory_threshold

# or

[heroku run || dotenv] rake:dynos:list_over_load_threshold
[heroku run || dotenv] rake:dynos:restart_over_load_threshold
```

## Details

This utility exposes 4 primary rake tasks, all under the `dynos` namespace:

### list_over_memory_threshold
Lists all web dynos currently over the memory threshold defined by `MEMORY_THRESHOLD_IN_MB`
### restart_over_memory_threshold
Restarts all web dynos currently over the memory threshold defined by `MEMORY_THRESHOLD_IN_MB`
### list_over_load_threshold
Lists all web dynos currently over the load threshold defined by `LOAD_1MIN_THRESHOLD`
### restart_over_load_threshold
Restarts all web dynos currently over the load threshold defined by `LOAD_1MIN_THRESHOLD`
