return
{
	packId = "voxel_teamwise",
	protocolVersion = 0,
	defaultPort = 9600,
	internalDirectoryPath = "config:voxel_teamwise/internal/",

	server =
	{
		globalDataFile = "global_data.vcbjson",
		playersDataFolder = "players",
		banListFile = "ban_list.json",
		whiteListFile = "whitelist.json",
		opsListFile = "ops.txt"
	},

	client =
	{
		multiplayerWorldName = "voxel_teamwise_multiplayer",
		reconnectSettingsFile = "reconnect_settings.json"
	}
}