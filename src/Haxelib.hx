import js.node.Buffer;
import js.node.ChildProcess;

class Haxelib {
	final folder:WorkspaceFolder;
	final installation:HaxeInstallationProvider;

	var libraries:Null<Array<String>>;

	public function new(folder, installation) {
		this.folder = folder;
		this.installation = installation;
	}

	public function getLibraries():Null<Array<String>> {
		if (libraries != null) {
			return libraries;
		}
		var haxelib = installation.installation.haxelibExecutable;
		if (haxelib == null) {
			return null;
		}
		try {
			var result:Buffer = ChildProcess.execSync('$haxelib search ""', {cwd: folder.uri.fsPath});
			var libraries = result.toString().split("\n").map(StringTools.trim);
			libraries.pop(); // empty line
			libraries.pop(); // "n libraries found"
			libraries.sort((a, b) -> Reflect.compare(a.toLowerCase(), b.toLowerCase()));
			return this.libraries = libraries;
		} catch (_:Any) {
			return null;
		}
	}
}
