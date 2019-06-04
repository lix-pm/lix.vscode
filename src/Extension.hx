import sys.io.File;
import sys.FileSystem;

class Extension {
	@:expose("activate")
	static function activate(context:ExtensionContext) {
		var folders = workspace.workspaceFolders;
		if (folders.length == 0) {
			return;
		}
		var folder = folders[0];

		var lix = new Lix(context, folder);
		new HaxeVersionSelector(context, lix);

		commands.registerCommand(LixCommand.InitializeProject, function() {
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
		});
	}
}
