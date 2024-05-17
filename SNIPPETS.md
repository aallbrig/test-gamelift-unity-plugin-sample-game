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
compute_name=$(grep -m 1 'ComputeName:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
ip_address=$(grep -m 1 'IpAddress:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
fleet_id=$(grep -m 1 'AnywhereFleetId:' $(git rev-parse --show-toplevel)/unity/gamelift-sample-test/GameLiftSettings.yaml | awk '{print $2}')
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