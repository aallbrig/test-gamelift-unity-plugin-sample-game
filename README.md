# Test Gamelift Unity Plugin's Sample Game
AWS Gamelift has a plugin for unity ([aws docs](https://docs.aws.amazon.com/gamelift/latest/developerguide/unity-plug-in.html), [plugin repo](https://github.com/aws/amazon-gamelift-plugin-unity)). The plugin evidently allows one to test a game server and game client locally, and then be able to push it up. This repo is simply documenting my experience testing everything. Its worth noting that I'm on a M2 macbook pro and am interested in running things in containers and connecting debuggers to processes. Lets see how the experience is.

## New Unity Project
```bash
gh repo create --public --clone test-gamelift-unity-plugin-sample-game && cd test-gamelift-unity-plugin-sample-game
echo -n ".idea\n.DS_Store" > .gitignore
mkdir -p unity
/Applications/Unity/Hub/Editor/2022.3.13f1/Unity.app/Contents/MacOS/Unity -createProject $(pwd)/unity/gamelift-sample-test
curl -o unity/gamelift-sample-test/.gitignore https://raw.githubusercontent.com/github/gitignore/main/Unity.gitignore
# add newly created project into unity hub
```

