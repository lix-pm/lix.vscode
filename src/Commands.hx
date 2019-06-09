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
		commands.registerCommand(LixCommand.InstallLibrary, installLibrary);
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

	function installLibrary() {
		var schemes = [Haxelib, GitHub, GitLab, Http, Https].map(scheme -> ({label: scheme} : QuickPickItem));
		window.showQuickPick(schemes, {placeHolder: "Select a scheme"}).then(function(pick) {
			if (pick == null) {
				return;
			}
			var scheme:Scheme = pick.label;
			window.showInputBox({placeHolder: scheme.arguments()}).then(function(args) {
				if (args != null) {
					trace('$scheme:$args');
				}
			});
		});
	}
}

private enum abstract Scheme(String) from String to String {
	var Haxelib = "haxelib";
	var GitHub = "github";
	var GitLab = "gitlab";
	var Http = "http";
	var Https = "https";

	public function arguments():String {
		return switch this {
			case Haxelib: "<name>[#<version>]";
			case GitHub | GitLab: "<owner>/<repo>[#<branch|tag|sha>]";
			case Http | Https: "<url>";
			case _: throw "wat";
		}
	}
}
