#!/usr/bin/env bash
# This script needs to rewritten, omg

function main() {
  fleet_id=$(grep -m 1 'AnywhereFleetId:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
  location=$(grep -m 1 'AnywhereFleetLocation:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
  region=$(grep -m 1 'Region:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
  start_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  start_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$start_time" "+%s")

  while true
  do
      # date commands for BSD because I'm on macbook pro
      # current_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      # two_minutes_ago=$(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ)
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
      [ "$available_game_sessions_metric_data" != "None" ] && [ -z "$first_available_game_session_time" ] && [ $(echo "$available_game_sessions_metric_data == 1.0" | bc) -eq 1 ] && {
        first_available_game_session_time=$(date -u +%Y-%m-%dT%H:%M:%SZ);
        first_available_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_available_game_session_time" "+%s")
        time_to_first_available=$((first_available_time_seconds - start_time_seconds))
        time_to_first_available_gs_min=$((time_to_first_available / 60))
        time_to_first_available_gs_sec=$((time_to_first_available % 60));
      }
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
      [ "$active_game_sessions_metric_data" != "None" ] && [ -z "$first_active_game_session_time" ] && [ $(echo "$active_game_sessions_metric_data == 1.0" | bc) -eq 1 ] && {
        first_active_game_session_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        first_active_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_active_game_session_time" "+%s")
        time_to_first_active=$((first_active_time_seconds - start_time_seconds))
        time_to_first_active_gs_min=$((time_to_first_active / 60))
        time_to_first_active_gs_sec=$((time_to_first_active % 60));
      }
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
      [ "$current_player_sessions_metric_data" != "None" ] && [ -z "$first_player_session_time" ] && [ $(echo "$current_player_sessions_metric_data >= 1" | bc) -eq 1 ] && {
        first_player_session_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        first_player_session_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_player_session_time" "+%s")
        time_to_first_player=$((first_player_session_time_seconds - start_time_seconds))
        time_to_first_player_session_min=$((time_to_first_player / 60))
        time_to_first_player_session_sec=$((time_to_first_player % 60));
      }
      current_abnormal_terminations_metric_data=$(aws cloudwatch get-metric-statistics \
          --namespace "AWS/GameLift" \
          --metric-name "ServerProcessAbnormalTerminations" \
          --dimensions Name=FleetId,Value=${fleet_id} Name=Location,Value=${location} \
          --statistics Sum \
          --period 30 \
          --start-time $(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ) \
          --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
          --region $region \
          --query 'Datapoints[0].Sum' --output text)
      [ "$current_abnormal_terminations_metric_data" != "None" ] && [ -z "$first_abnormal_server_time" ] && [ $(echo "$current_abnormal_terminations_metric_data >= 1" | bc) -eq 1 ] && {
         first_abnormal_server_time=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
         first_abnormal_server_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_abnormal_server_time" "+%s")
         time_to_first_abnormal_server=$((first_player_session_time_seconds - start_time_seconds))
         time_to_first_abnormal_termination_min=$((time_to_first_abnormal_server / 60))
         time_to_first_abnormal_termination_sec=$((time_to_first_abnormal_server % 60));
      }
      active_server_processes_metric_data=$(aws cloudwatch get-metric-statistics \
          --namespace "AWS/GameLift" \
          --metric-name "ActiveServerProcesses" \
          --dimensions Name=FleetId,Value=${fleet_id} Name=Location,Value=${location} \
          --statistics Sum \
          --period 30 \
          --start-time $(date -u -v-2M +%Y-%m-%dT%H:%M:%SZ) \
          --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
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
      [ "$healthy_server_processes_metric_data" != "None" ] && [ -z "$first_healthy_processes_time" ] && [ $(echo "$healthy_server_processes_metric_data >= 1" | bc) -eq 1 ] && {
         first_healthy_processes_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
         first_healthy_processes_time_seconds=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$first_healthy_processes_time" "+%s")
         time_to_first_healthy_gs_min=$((first_healthy_processes_time_seconds / 60))
         time_to_first_healthy_gs_sec=$((first_healthy_processes_time_seconds % 60));
      }

      if [ -n "$first_available_game_session_time" ] && [ -n "$first_active_game_session_time" ]; then
        time_to_first_active_from_available=$((first_active_time_seconds - first_available_time_seconds))
        time_to_first_active_from_available_gs_min=$((time_to_first_active_from_available / 60))
        time_to_first_active_from_available_gs_sec=$((time_to_first_active_from_available % 60))
      fi

      clear
      echo "active instance latest metric: $active_instance_metric_data"
      echo "healthy server processes latest metric: $current_healthy_processes_metric_data"
      echo "active server processes latest metric: $active_server_processes_metric_data"
      echo "healthy server process latest metric: $healthy_server_processes_metric_data"
      echo "available game sessions latest metric: $available_game_sessions_metric_data"
      echo "active game sessions latest metric: $active_game_sessions_metric_data"
      echo "current player sessions latest metric: $current_player_sessions_metric_data"
      echo "current abnormal game session termination latest metric: $current_abnormal_terminations_metric_data"
      echo

      [ ! -z "$time_to_first_healthy_gs_min" ] && [ ! -z "$time_to_first_healthy_gs_sec" ] && echo "Time to first healthy server process: ${time_to_first_healthy_gs_min} minutes and ${time_to_first_healthy_gs_sec} seconds"
      [ ! -z "$time_to_first_available_gs_min" ] && [ ! -z "$time_to_first_available_gs_sec" ] && echo "Time to first available game session: ${time_to_first_available_gs_min} minutes and ${time_to_first_available_gs_sec} seconds"
      [ ! -z "$time_to_first_active_gs_min" ] && [ ! -z "$time_to_first_active_gs_sec" ] && echo "Time to first active game session: ${time_to_first_active_gs_min} minutes and ${time_to_first_active_gs_sec} seconds"
      [ ! -z "$time_to_first_active_from_available_gs_min" ] && [ ! -z "$time_to_first_active_from_available_gs_sec" ] && echo "Time to first active game session, from available status: ${time_to_first_active_from_available_gs_min} minutes and ${time_to_first_active_from_available_gs_sec} seconds"
      [ ! -z "$time_to_first_player_session_min" ] && [ ! -z "$time_to_first_player_session_sec" ] && echo "Time to first player session: ${time_to_first_player_session_min} minutes and ${time_to_first_player_session_sec} seconds"
      [ ! -z "$time_to_first_abnormal_termination_min" ] && [ ! -z "$time_to_first_abnormal_termination_sec" ] && echo "Time to abnormal game session termination: ${time_to_first_abnormal_termination_min} minutes and ${time_to_first_abnormal_termination_sec} seconds"

      sleep 1
  done
}

main