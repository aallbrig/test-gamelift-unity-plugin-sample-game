using UnityEditor;

namespace Editor
{
    public static class BuildBuilder
    {
        private static readonly string[] Scenes = {
                "Assets/Scenes/BootstrapScene.unity",
                "Assets/Scenes/GameScene.unity" };
        [MenuItem("Game/Builder/Build OSX (debug)")]
        public static void BuildClient_OSX_debug()
        {
            BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = Scenes,
                locationPathName = "Builds/OSX_amd64_debug/game.client.app",
                target = BuildTarget.StandaloneOSX,
                options = BuildOptions.Development | BuildOptions.AllowDebugging
            });
        }
    }
}
