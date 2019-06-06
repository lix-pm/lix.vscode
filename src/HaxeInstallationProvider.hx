import sys.FileSystem;
import vshaxe.HaxeInstallation;

class HaxeInstallationProvider {
	final folder:WorkspaceFolder;
	final lix:Lix;
	var provideInstallation:HaxeInstallation->Void;

	public function new(folder, lix) {
		this.folder = folder;
		this.lix = lix;
		lix.onDidChangeScope(_ -> update());
	}

	public function activate(provideInstallation:HaxeInstallation->Void) {
		this.provideInstallation = provideInstallation;
		update();
	}

	function update() {
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

	public function deactivate() {}
}
