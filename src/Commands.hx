import sys.io.File;
import sys.FileSystem;

class Commands {
	final folder:WorkspaceFolder;
	final lix:Lix;

	public function new(folder, lix) {
		this.folder = folder;
		this.lix = lix;

		commands.registerCommand(LixCommand.InitializeProject, initializeProject);
		commands.registerCommand(LixCommand.DownloadMissingLibraries, downloadMissingLibraries);
	}

	function initializeProject() {
		var path = folder.uri.fsPath;
		Scope.create(path, {
			version: "latest",
			resolveLibs: Scoped
		});
		var packageJson = '$path/package.json';
		if (!FileSystem.exists(packageJson)) {
			File.saveContent(packageJson, '{\n\t"devDependencies": {}\n}');
		}
		var terminal = window.createTerminal();
		terminal.show();
		terminal.sendText("npm install lix --save-dev");
	}

	function downloadMissingLibraries() {
		var haxeVersion = lix.scope.config.version;
		Util.withProgress('Downloading Haxe $haxeVersion...', lix.switcher.resolveOnline(haxeVersion).next(lix.switcher.download.bind(_, {force: false})))
			.then(function(_) {
				// TODO: report progress?
				Util.withProgress('Downloading Libraries...', lix.scope.installLibs());
			});
	}
}
