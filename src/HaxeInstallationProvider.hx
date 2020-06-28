import haxe.io.Path;
import js.node.Buffer;
import js.node.ChildProcess;
import sys.FileSystem;
import vshaxe.HaxeInstallation;
import vshaxe.Library;

class HaxeInstallationProvider {
	public var resolveLibrary:(classpath:String) -> Null<Library>;
	public var listLibraries:() -> Array<{name:String}>;
	public var installation(default, null):HaxeInstallation = {};

	final folder:WorkspaceFolder;
	final lix:Lix;
	final vshaxe:Vshaxe;
	var provideInstallation:HaxeInstallation->Void;
	var disposable:Disposable;
	var npmPrefix:Null<String>;

	public function new(folder, lix, vshaxe) {
		this.folder = folder;
		this.lix = lix;
		this.vshaxe = vshaxe;
		this.resolveLibrary = resolveLibraryImpl;
		this.listLibraries = listLibrariesImpl;

		lix.onDidChangeScope(function(_) {
			updateRegistration();
			updateInstallation();
		});
		updateRegistration();
	}

	function updateRegistration() {
		if (lix.active) {
			if (disposable == null) {
				disposable = vshaxe.registerHaxeInstallationProvider("lix", this);
			}
		} else {
			if (disposable != null) {
				disposable.dispose();
				disposable = null;
			}
		}
	}

	public function activate(provideInstallation:HaxeInstallation->Void) {
		this.provideInstallation = provideInstallation;
		updateInstallation();
	}

	function updateInstallation() {
		if (provideInstallation == null) {
			return;
		}
		var isWindows = Sys.systemName() == "Windows";
		var haxeExecutable = if (isWindows) "node_modules\\.bin\\haxe.cmd" else "node_modules/.bin/haxe";
		var haxelibExecutable = if (isWindows) "node_modules\\.bin\\haxelib.cmd" else "node_modules/.bin/haxelib";
		var cwd = folder.uri.fsPath;

		// if there's no local lix installation, let's see if there's a global one
		if (!FileSystem.exists('$cwd/$haxeExecutable')) {
			var globalHaxeExecutable = Path.join([getNpmPrefix(), "haxe"]);
			if (isWindows) {
				globalHaxeExecutable += ".cmd";
			}
			haxeExecutable = if (FileSystem.exists(globalHaxeExecutable)) globalHaxeExecutable else null;
		}
		if (!FileSystem.exists('$cwd/$haxelibExecutable')) {
			var globalHaxelibExecutable = Path.join([getNpmPrefix(), "haxelib"]);
			if (isWindows) {
				globalHaxelibExecutable += ".cmd";
			}
			haxelibExecutable = if (FileSystem.exists(globalHaxelibExecutable)) globalHaxelibExecutable else null;
		}

		installation = {
			haxeExecutable: haxeExecutable,
			haxelibExecutable: haxelibExecutable,
			standardLibraryPath: lix.scope.haxeInstallation.stdLib
		}
		provideInstallation(installation);
	}

	function getNpmPrefix():Null<String> {
		if (npmPrefix == null) {
			try {
				npmPrefix = (ChildProcess.execSync("npm config get prefix") : Buffer).toString().trim();
			} catch (e:Any) {}
		}
		return npmPrefix;
	}

	public function deactivate() {
		provideInstallation = null;
	}

	function resolveLibraryImpl(classpath:String):Null<Library> {
		classpath = Path.normalize(classpath);
		var libCache = Path.addTrailingSlash(Path.normalize(lix.scope.libCache));
		if (!classpath.startsWith(libCache)) {
			return null;
		}
		var parts = classpath.replace(libCache, "").split("/");
		var name = parts[0];
		var version = parts[1];
		var scheme = parts[2];

		var path = Path.join([libCache, name, version, scheme]);
		if (scheme == "github" || scheme == "gitlab") {
			var shortenedSha = parts[3].substr(0, 7);
			version = if (version == "0.0.0") shortenedSha else '$version, $shortenedSha';
			path = Path.join([path, parts[3]]);
		}
		return {
			name: name,
			version: version,
			path: path
		};
	}

	function listLibrariesImpl():Array<{name:String}> {
		final haxeLibraries = lix.scope.scopeLibDir;
		if (!FileSystem.exists(haxeLibraries) || !FileSystem.isDirectory(haxeLibraries)) {
			return [];
		}
		return FileSystem.readDirectory(haxeLibraries)
			.filter(file -> file.endsWith(".hxml"))
			.map(file -> {name: file.substr(0, file.length - ".hxml".length)});
	}
}
