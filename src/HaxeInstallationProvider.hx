import sys.FileSystem;
import vshaxe.HaxeInstallation;

class HaxeInstallationProvider {
	final folder:WorkspaceFolder;
	final lix:Lix;
	final vshaxe:Vshaxe;
	var provideInstallation:HaxeInstallation->Void;
	var disposable:Disposable;

	public function new(folder, lix, vshaxe) {
		this.folder = folder;
		this.lix = lix;
		this.vshaxe = vshaxe;

		lix.onDidChangeScope(function(_) {
			updateInstallation();
			updateRegistration();
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
		provideInstallation({
			haxeExecutable: if (FileSystem.exists('$cwd/$haxeExecutable')) haxeExecutable else null,
			haxelibExecutable: if (FileSystem.exists('$cwd/$haxelibExecutable')) haxelibExecutable else null,
			standardLibraryPath: lix.scope.haxeInstallation.stdLib,
			libraryBasePath: lix.scope.libCache
		});
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
}
