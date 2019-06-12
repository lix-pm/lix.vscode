import sys.io.File;
import sys.FileSystem;

class Commands {
	final folder:WorkspaceFolder;
	final lix:Lix;
	final haxelib:Haxelib;

	public function new(folder, lix, haxelib) {
		this.folder = folder;
		this.lix = lix;
		this.haxelib = haxelib;

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
		lix.run(["download"]);
	}

	function installLibrary() {
		var schemes = toQuickPickItems([Haxelib, GitHub, GitLab, Http, Https]);
		window.showQuickPick(schemes, {placeHolder: "Select a scheme"}).then(function(pick) {
			if (pick == null) {
				return;
			}
			var scheme:Scheme = pick.label;
			var options = {placeHolder: scheme.arguments()};
			function handleArgs(args) {
				if (args != null) {
					lix.run(["install", '$scheme:$args']);
				}
			}

			if (scheme == Haxelib) {
				var libs = toQuickPickItems(haxelib.getLibraries());
				if (libs == null) {
					window.showInputBox(options).then(handleArgs);
				} else {
					window.showQuickPick(libs, options).then(item -> {
						if (item != null) {
							handleArgs(item.label);
						}
					});
				}
			} else {
				window.showInputBox(options).then(handleArgs);
			}
		});
	}

	function toQuickPickItems(a:Array<String>):Array<QuickPickItem> {
		return a.map(s -> ({label: s} : QuickPickItem));
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
