# Snippets
Bash command snippet scratchpad.

__Check for differences between the unity plugin sample game's Assets folder with files found in my own project's Assets folder__
```bash
# clone unity plugin, latest commit only
[ -d /tmp/amazon-gamelift-plugin-unity ] || git clone https://github.com/aws/amazon-gamelift-plugin-unity.git /tmp/amazon-gamelift-plugin-unity --depth 1
# compare it's sample project Asset .cs files with same ones found in project's Assets folder
source_dir='/tmp/amazon-gamelift-plugin-unity/Samples~/SampleGame/Assets'
target_dir="$(git rev-parse --show-toplevel)/unity/gamelift-sample-test/Assets"
find $source_dir -type f -name '*.cs' | while read -r source_file; do
  relative_path="${source_file#$source_dir/}"
  target_file="$target_dir/$relative_path"
  if [ -f "$target_file" ]; then
    echo "Diffing $source_file and $target_file"
    diff -w $source_file $target_file
  else
    echo "file $target_file does not exist (clone over?)"
  fi
done
```
__Get fleet id(s) that are anywhere fleets__
```bash
for fleet_id in $(aws gamelift list-fleets --query 'FleetIds' --output text); do
  # echo "fleet id: $fleet_id"
  compute_type=$(aws gamelift describe-fleet-attributes --fleet-id "$fleet_id" --query 'FleetAttributes[0].ComputeType' --output text)
  # echo "compute_type: $compute_type"
  if ! [ "$compute_type" = "ANYWHERE" ]; then
    # echo "not anywhere fleet"
    continue 
  fi
  echo "anywhere fleet id: $fleet_id"
done
```
__Check that resources exist created by the gamelift unity plugin when using the 'Host with Anywhere' plugin tab (assume default values)
```bash
fleet_id=$(grep -m 1 'AnywhereFleetId:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
compute_name=$(grep -m 1 'ComputeName:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
ip_address=$(grep -m 1 'IpAddress:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
output=$(aws gamelift list-compute --fleet-id $fleet_id --output json)
compute_name=$(echo "$output" | jq -r '.ComputeList[0].ComputeName')
ip_address=$(echo "$output" | jq -r '.ComputeList[0].IpAddress')
location=$(echo "$output" | jq -r '.ComputeList[0].Location')
if [ "$compute_name" = "ComputerName-ProfileName" ] && [ "$ip_address" = "127.0.0.1" ]; then
  echo "Found compute matching values from GameLiftSettings.yaml"
else
  echo "No match found"
fi
locations_output=$(aws gamelift list-locations --filters CUSTOM --output json)
location_exists=$(echo "$locations_output" | jq -r --arg loc "$location" '.Locations[] | select(.LocationName == $loc) | .LocationName')
if [ -n "$location_exists" ]; then
  echo "Location $location exists."
else
  echo "Location $location does not exist."
fi
```
__Make sure `GameLiftAnywhereClientSettings.yaml` exists in game client build folder__
```bash
# make sure GameLiftAnywhereClientSettings.yaml exists in game client build folder
game_client_build_dir="$(git rev-parse --show-toplevel)/unity/gamelift-sample-test/Builds/OSX_amd64_dev"
[ -f "$game_client_build_dir/GameLiftAnywhereClientSettings.yaml" ] && echo "Found GameLiftAnywhereClientSettings.yaml" || echo "GameLiftAnywhereClientSettings.yaml does not exist in $game_client_build_dir"
```
__(WIP) How to tell when unity editor game server is ready to receive game client connects, from aws gamelift perspective__
```bash
fleet_id=$(grep -m 1 'AnywhereFleetId:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
location=$(grep -m 1 'AnywhereFleetLocation:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
region=$(grep -m 1 'Region:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
start_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
first_available_game_session_time=""
first_active_game_session_time=""
first_player_session_time=""
game_session_time=""
while true
do
    # date commands for BSD because I'm on macbook pro
    current_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    two_minutes_ago=$(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ)
    active_instance_metric_data=$(aws cloudwatch get-metric-statistics \
        --namespace "AWS/GameLift" \
        --metric-name "ActiveInstances" \
        --dimensions Name=FleetId,Value=${fleet_id} Name=Location,Value=${location} \
        --statistics Maximum \
        --period 30 \
        --start-time $(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --region $region \
        --query 'Datapoints[0].Maximum')
    active_server_processes_metric_data=$(aws cloudwatch get-metric-statistics \
        --namespace "AWS/GameLift" \
        --metric-name "ActiveServerProcesses" \
        --dimensions Name=FleetId,Value=${fleet_id} Name=Location,Value=${location} \
        --statistics Sum \
        --period 30 \
        --start-time $(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $current_time \
        --region $region \
        --query 'Datapoints[0].Sum' --output text)
    healthy_server_processes_metric_data=$(aws cloudwatch get-metric-statistics \
        --namespace "AWS/GameLift" \
        --metric-name "HealthyServerProcesses" \
        --dimensions Name=FleetId,Value=${fleet_id} Name=Location,Value=${location} \
        --statistics Average \
        --period 30 \
        --start-time $(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --region $region \
        --query 'Datapoints[0].Average' --output text)
    available_game_sessions_metric_data=$(aws cloudwatch get-metric-statistics \
        --namespace "AWS/GameLift" \
        --metric-name "AvailableGameSessions" \
        --dimensions Name=FleetId,Value=${fleet_id} Name=Location,Value=${location} \
        --statistics Sum \
        --period 30 \
        --start-time $(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --region $region \
        --query 'Datapoints[0].Sum' --output text)
    [ -z $first_available_game_session_time ] && [ $available_game_sessions_metric_data = 1.0 ] && first_available_game_session_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    active_game_sessions_metric_data=$(aws cloudwatch get-metric-statistics \
        --namespace "AWS/GameLift" \
        --metric-name "ActiveGameSessions" \
        --dimensions Name=FleetId,Value=${fleet_id} Name=Location,Value=${location} \
        --statistics Sum \
        --period 30 \
        --start-time $(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --region $region \
        --query 'Datapoints[0].Sum' --output text)
    [ -z $first_active_game_session_time ] && [ $active_game_sessions_metric_data = 1.0 ] && first_active_game_session_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    current_player_sessions_metric_data=$(aws cloudwatch get-metric-statistics \
        --namespace "AWS/GameLift" \
        --metric-name "CurrentPlayerSessions" \
        --dimensions Name=FleetId,Value=${fleet_id} Name=Location,Value=${location} \
        --statistics Sum \
        --period 30 \
        --start-time $(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --region $region \
        --query 'Datapoints[0].Sum' --output text)
    [ -z $first_player_session_time ] && [ $current_player_sessions_metric_data = 1.0 ] && first_player_session_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    clear
    echo "active instance latest metric: $active_instance_metric_data"
    echo "active server processes latest metric: $active_server_processes_metric_data"
    echo "healthy server process latest metric: $healthy_server_processes_metric_data"
    echo "available game sessions latest metric: $available_game_sessions_metric_data"
    echo "active game sessions latest metric: $active_game_sessions_metric_data"
    echo "current player sessions latest metric: $current_player_sessions_metric_data"
    if [ ! -z "$first_available_game_session_time" ]; then
      start_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$start_time" "+%s")
      first_available_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_available_game_session_time" "+%s")
      time_to_first_available=$((first_available_time_seconds - start_time_seconds))
      time_to_first_available_min=$((time_to_first_available / 60))
      time_to_first_available_sec=$((time_to_first_available % 60))
      echo "Time to first available game session: ${time_to_first_available_min} minutes and ${time_to_first_available_sec} seconds"
    fi
    if [ ! -z "$first_player_session_time" ]; then
      start_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$start_time" "+%s")
      first_available_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_player_session_time" "+%s")
      time_to_first_available=$((first_available_time_seconds - start_time_seconds))
      time_to_first_available_min=$((time_to_first_available / 60))
      time_to_first_available_sec=$((time_to_first_available % 60))
      echo "Time to first player session: ${time_to_first_available_min} minutes and ${time_to_first_available_sec} seconds"
    fi
    if [ ! -z "$first_available_game_session_time" ] && [ ! -z "$first_active_game_session_time" ]; then
      first_available_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_available_game_session_time" "+%s")
      first_active_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_active_game_session_time" "+%s")
      time_to_first_active=$((first_active_time_seconds - first_available_time_seconds))
      time_to_first_active_min=$((time_to_first_active / 60))
      time_to_first_active_sec=$((time_to_first_active % 60))
      echo "Time to first active game session, after becoming available: ${time_to_first_active_min} minutes and ${time_to_first_active_sec} seconds"
    fi
    sleep 1
done
```