import js.node.Buffer;
import js.node.ChildProcess;
import sys.io.File;
import sys.FileSystem;
import lix.cli.Cli;

class Commands {
	final folder:WorkspaceFolder;
	final lix:Lix;
	final installation:HaxeInstallationProvider;

	public function new(folder, lix, installation) {
		this.folder = folder;
		this.lix = lix;
		this.installation = installation;

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
		var schemes = toQuickPickItems([Haxelib, GitHub, GitLab, Http, Https]);
		window.showQuickPick(schemes, {placeHolder: "Select a scheme"})
			.then(function(pick) {
				if (pick == null) {
					return;
				}
				var scheme:Scheme = pick.label;
				var options = {placeHolder: scheme.arguments()};
				function handleArgs(args) {
					if (args == null) {
						return;
					}
					// TODO: report progress + errors
					Sys.setCwd(folder.uri.fsPath);
					@:privateAccess Cli.dispatch(["install", '$scheme:$args']);
				}

				if (scheme == Haxelib) {
					var libs = toQuickPickItems(getHaxelibs());
					if (libs == null) {
						window.showInputBox(options)
							.then(handleArgs);
					} else {
						window.showQuickPick(libs, options)
							.then(item -> {
								if (item != null) {
									handleArgs(item.label);
								}
							});
					}
				} else {
					window.showInputBox(options)
						.then(handleArgs);
				}
			});
	}

	function getHaxelibs():Null<Array<String>> {
		var haxelib = installation.installation.haxelibExecutable;
		if (haxelib == null) {
			return null;
		}
		try {
			var result:Buffer = ChildProcess.execSync('$haxelib search ""', {cwd: folder.uri.fsPath});
			var libs = result.toString().split("\n");
			libs.pop(); // empty line
			libs.pop(); // "n libraries found"
			libs.sort(Reflect.compare);
			return libs;
		} catch (_:Any) {
			return null;
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
