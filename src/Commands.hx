import js.node.ChildProcess;
import sys.io.File;

using sys.FileSystem;
using haxe.io.Path;

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
		commands.registerCommand(LixCommand.UpdateLibrary, ensureScope(updateLibrary));
		commands.registerCommand(LixCommand.SelectHaxeVersion, ensureScope(selector.selectHaxeVersion));
	}

	function initializeProject() {
		try {
			var path = folder.uri.fsPath;
			var packageJson = '$path/package.json';
			if (!FileSystem.exists(packageJson)) {
				File.saveContent(packageJson, '{\n\t"devDependencies": {}\n}');
			}
			ChildProcess.execSync("npm install lix --save-dev", {cwd: path});
			Scope.create(path, {
				version: "latest",
				resolveLibs: Scoped
			}).eager();
		} catch (e:Any) {
			window.showErrorMessage(Std.string(e));
		}
	}

	function ensureScope(f:() -> Void) {
		return function() {
			if (!lix.active) {
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

	function updateLibrary() {
		var libs = new Map<String, String>();
		var scopeLibDir = lix.scope.scopeLibDir;
		if (lix.scope.scopeLibDir.exists()) {
			for (child in scopeLibDir.readDirectory()) {
				var path = '$scopeLibDir/$child';
				if (path.isDirectory() || !path.endsWith('.hxml')) {
					continue;
				}
				var hxml = File.getContent(path);
				var directives = @:privateAccess lix.scope.parseDirectives(hxml);
				// this surely isn't the optimal way to do this...
				final regex = ~/download "(.*?)" into/;
				var directive = directives["install"];
				if (directive == null || directive[0] == null || !regex.match(directive[0])) {
					continue;
				}
				var arg = regex.matched(1);
				var hashIndex = arg.lastIndexOf("#");
				if (hashIndex != -1) {
					arg = arg.substr(0, hashIndex);
				}
				var name = path.withoutDirectory().withoutExtension();
				libs[name] = arg;
			}
		}

		var items = toQuickPickItems([for (lib in libs.keys()) lib]);
		if (items.length == 0) {
			window.showInformationMessage("No libraries found in the current scope.");
		} else {
			window.showQuickPick(items, {placeHolder: "Select a Library to Update"}).then(function(pick) {
				if (pick != null) {
					lix.run(["install", libs[pick.label]]);
				}
			});
		}
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
