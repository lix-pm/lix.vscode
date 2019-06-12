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

	function run(command:String):Null<Array<String>> {
		var haxelib = installation.installation.haxelibExecutable;
		if (haxelib == null) {
			return null;
		}
		try {
			var result:Buffer = ChildProcess.execSync('$haxelib $command', {cwd: folder.uri.fsPath});
			var output = result.toString().split("\n").map(StringTools.trim);
			output.pop(); // empty line
			return output;
		} catch (_:Any) {
			return null;
		}
	}

	public function getLibraries():Null<Array<String>> {
		if (libraries != null) {
			return libraries;
		}
		var libraries = run('search ""');
		libraries.pop(); // "n libraries found"
		libraries.sort((a, b) -> Reflect.compare(a.toLowerCase(), b.toLowerCase()));
		return this.libraries = libraries;
	}
}
