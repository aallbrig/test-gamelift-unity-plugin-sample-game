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
```
Use gamelift anywhere features to test multiplayer server interactions locally.
