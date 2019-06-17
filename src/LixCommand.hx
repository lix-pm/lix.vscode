enum abstract LixCommand(String) to String {
	var SelectHaxeVersion = "lix.selectHaxeVersion";
	var CreateScope = "lix.createScope";
	var InitializeProject = "lix.initializeProject";
	var DownloadMissingDependencies = "lix.downloadMissingDependencies";
	var InstallLibrary = "lix.installLibrary";
	var UpdateLibrary = "lix.updateLibrary";
}
