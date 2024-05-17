# Test Gamelift Unity Plugin's Sample Game
AWS Gamelift has a plugin for unity ([aws docs](https://docs.aws.amazon.com/gamelift/latest/developerguide/unity-plug-in.html), [plugin repo](https://github.com/aws/amazon-gamelift-plugin-unity)). The plugin evidently allows one to test a game server and game client locally, and then be able to push it up. This repo is simply documenting my experience testing everything. Its worth noting that I'm on a M2 macbook pro and am interested in running things in containers and connecting debuggers to processes. Lets see how the experience is.

### New Unity Project
```bash
gh repo create --public --clone test-gamelift-unity-plugin-sample-game && cd test-gamelift-unity-plugin-sample-game
echo -n ".idea\n.DS_Store" > .gitignore
mkdir -p unity
/Applications/Unity/Hub/Editor/2022.3.13f1/Unity.app/Contents/MacOS/Unity -createProject $(pwd)/unity/gamelift-sample-test
curl -o unity/gamelift-sample-test/.gitignore https://raw.githubusercontent.com/github/gitignore/main/Unity.gitignore
# add newly created project into unity hub (manual)
```

### Install Plugin (and prereqs)
https://github.com/aws/amazon-gamelift-plugin-unity?tab=readme-ov-file#install-the-plugin
```bash
# list releases
gh release list --repo aws/amazon-gamelift-plugin-unity
# see latest release's assets
release view --repo aws/amazon-gamelift-plugin-unity --json assets
# download asset into Packages
plugin_asset_url=$(gh release view --repo aws/amazon-gamelift-plugin-unity --json assets --jq '.assets[] | select(.name | contains("gamelift-plugin-unity")) | .url')
plugin_zip_filename=$(basename $plugin_asset_url)
plugin_folder=$(basename $plugin_zip_filename .zip)
# curl -L $plugin_asset_url -o $(pwd)/unity/gamelift-sample-test/Packages/$plugin_zip_filename
curl -L $plugin_asset_url -o /tmp/$plugin_zip_filename
mkdir -p /tmp/$plugin_folder
unzip /tmp/$plugin_zip_filename -d /tmp/$plugin_folder
find /tmp/$plugin_folder -type file -name '*.zip' | sed 's/.zip//g' | xargs -I{} unzip {}.zip -d {}
find /tmp/$plugin_folder -type file -name '*.tgz' | xargs -I{} mv {} $(pwd)/unity/gamelift-sample-test/Packages
# (manual) follow instructions to use unity editor's GUI to import the tarfile packages
# (undocumented) this package requires com.unity.ui
# (manual) follow instructions to set up the new test project provided by aws gamelift unity plugin
# ignore GameLiftSettings.yaml file
echo 'GameLiftSettings.yaml' >> unity/gamelift-sample-test/.gitignore
```
Use gamelift anywhere features to test multiplayer server interactions locally.

__Note:__ While using my VPN I found that the game client crashed when trying to connect to the multiplayer game server in my unity editor.

__Note:__ I found similar issues when using gamelift anywhere from my phone's hotspot. Not sure why this is happening and I'll have to attach a debugger to the game client process to see where the game client code is failing under these two noted conditions.

### Gamelift Unity Plugin + GameLift Anywhere + VPN observations
- Set up internet connection in one of four configurations (regular internet, VPN internet, phone hotspot, phone hotspot + phone VPN)
- Produce dev build of OSX game client
- Stop/Start game server in unity editor
- Close/Start OSX game client

| Observation No. | Regular Internet                                   | VPN Internet | Phone Hotspot | Phone Hotspot + Phone VPN |
| --------------- |----------------------------------------------------| ------------ | ------------- | ------------------------- |
| 1               | ✅(no wait)                                         |              |               |                           |
| 2               | ✅(no wait)                                         |              |               |                           |
| 3               | ❌(client start before server healthcheck log)      |              |               |                           |
| 4               | ❌(client start right after server healthcheck log) |              |               |                           |
| 5               | ✅(no wait)                                         |              |               |                           |
| 6               | ❌(no wait)                                         |              |               |                           |
| 7               | ❌(after 2nd healthcheck log from server)           |              |               |                           |
| 8               | ❌(no wait)                                         |              |               |                           |
| 9               | ❌(no wait)                                         |              |               |                           |
| 10              | ❌(no wait)                                         |              |               |                           |

__Note:__ Sometimes I have to fully reset the gamelift anywhere when I move locations, by going into the AWS gamelift dashboard deleting resources and recreating them in the gamelift plugin UI in unity editor. I also do this when switching between internet configuration, just to observe from a clean place. Restart unity editor so the plugin fully detects deleted fleets & locations. Rebuild the game client after this reset, in case that's important too.

__Note:__ On a failed test, the game client app will be in "not responding" state. Open activity monitor and force close the application to be able to restart.

__Note:__ Sometimes when rebuilding the game client, in the build folder will appear `GameLiftServerRuntimeSettings.yaml` instead of `GameLiftAnywhereClientSettings.yaml`. When I start the game client with the `GameLiftServerRuntimeSettings.yaml` file will result in errors in the game client. Given I'm building the game client using a build script (see `BuildBuilder.cs` file), I'm uncertain why one file or the other shows up, lol. I confirmed that the `GameLiftClientSettings` scriptable object still has the "Use GameLift Anywhere" checkmark checked.
