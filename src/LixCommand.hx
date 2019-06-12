enum abstract LixCommand(String) to String {
	var InitializeProject = "lix.initializeProject";
	var DownloadMissingDependencies = "lix.downloadMissingDependencies";
	var InstallLibrary = "lix.installLibrary";
	var SelectHaxeVersion = "lix.selectHaxeVersion";
}
