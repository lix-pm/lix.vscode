import haxe.io.Path;
import sys.FileSystem;
import vshaxe.Library;
import vshaxe.HaxeInstallation;

class HaxeInstallationProvider {
	public var resolveLibrary:(classpath:String) -> Null<Library>;
	public var installation(default, null):HaxeInstallation = {};

	final folder:WorkspaceFolder;
	final lix:Lix;
	final vshaxe:Vshaxe;
	var provideInstallation:HaxeInstallation->Void;
	var disposable:Disposable;

	public function new(folder, lix, vshaxe) {
		this.folder = folder;
		this.lix = lix;
		this.vshaxe = vshaxe;
		this.resolveLibrary = resolveLibraryImpl;

		lix.onDidChangeScope(function(_) {
			updateRegistration();
			updateInstallation();
		});
		updateRegistration();
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
		installation = {
			haxeExecutable: if (FileSystem.exists('$cwd/$haxeExecutable')) haxeExecutable else null,
			haxelibExecutable: if (FileSystem.exists('$cwd/$haxelibExecutable')) haxelibExecutable else null,
			standardLibraryPath: lix.scope.haxeInstallation.stdLib
		}
		provideInstallation(installation);
	}

	public function deactivate() {
		provideInstallation = null;
	}

	function updateRegistration() {
		if (lix.scope.isGlobal) {
			if (disposable != null) {
				disposable.dispose();
				disposable = null;
			}
		} else {
			if (disposable == null) {
				disposable = vshaxe.registerHaxeInstallationProvider("lix", this);
			}
		}
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
}
