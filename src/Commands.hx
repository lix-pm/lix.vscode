import sys.io.File;
import sys.FileSystem;

class Commands {
	final folder:WorkspaceFolder;
	final lix:Lix;
	final haxelib:Haxelib;

	public function new(folder, lix, haxelib, selector:HaxeVersionSelector) {
		this.folder = folder;
		this.lix = lix;
		this.haxelib = haxelib;

		commands.registerCommand(LixCommand.InitializeProject, initializeProject);
		commands.registerCommand(LixCommand.DownloadMissingDependencies, ensureScope(downloadMissingDependencies));
		commands.registerCommand(LixCommand.InstallLibrary, ensureScope(installLibrary));
		commands.registerCommand(LixCommand.SelectHaxeVersion, ensureScope(selector.selectHaxeVersion));
	}

	function initializeProject() {
		var path = folder.uri.fsPath;
		Scope.create(path, {
			version: "latest",
			resolveLibs: Scoped
		}).eager();
		var packageJson = '$path/package.json';
		if (!FileSystem.exists(packageJson)) {
			File.saveContent(packageJson, '{\n\t"devDependencies": {}\n}');
		}
		var terminal = window.createTerminal();
		terminal.show();
		terminal.sendText("npm install lix --save-dev");
	}

	function ensureScope(f:() -> Void) {
		return function() {
			if (lix.scope.isGlobal) {
				var InitializeProject = "Initialize Project";
				window.showErrorMessage("No .haxerc / local scope found.", InitializeProject, "Close").then(function(pick) {
					if (pick == InitializeProject) {
						initializeProject();
					}
				});
			} else {
				f();
			}
		}
	}

	function downloadMissingDependencies() {
		lix.run(["download"]);
	}

	function installLibrary() {
		var schemes = toQuickPickItems([Haxelib, GitHub, GitLab, Http, Https]);
		window.showQuickPick(schemes, {placeHolder: "Select Scheme"}).then(function(pick) {
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
				var libs = haxelib.getLibraries();
				if (libs == null) {
					window.showInputBox(options).then(handleArgs);
				} else {
					window.showQuickPick(toQuickPickItems(libs), {placeHolder: "Select Library"}).then(function(pick) {
						if (pick == null) {
							return;
						}
						var library = pick.label;
						var releases = haxelib.getReleases(library);
						if (releases != null) {
							var releaseItems = releases.map(release -> ({
								label: release.version,
								description: release.date + " - " + release.releaseNotes
							} : QuickPickItem));
							window.showQuickPick(releaseItems, {placeHolder: "Select Version"}).then(function(pick) {
								if (pick != null) {
									handleArgs('$library#${pick.label}');
								}
							});
						} else {
							handleArgs(library);
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
