import js.node.Buffer;
import js.node.ChildProcess;

class Haxelib {
	final folder:WorkspaceFolder;
	final installation:HaxeInstallationProvider;

	var libraries:Null<Array<String>>;
	var releases = new Map<String, Array<Release>>();

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
		if (libraries == null) {
			return null;
		}
		libraries.pop(); // "n libraries found"
		libraries.sort((a, b) -> Reflect.compare(a.toLowerCase(), b.toLowerCase()));
		return this.libraries = libraries;
	}

	public function getReleases(library:String):Null<Array<Release>> {
		var releases = this.releases[library];
		if (releases != null) {
			return releases;
		}
		var output = run('info $library');
		if (output == null) {
			return null;
		}
		var releaseIndex = output.indexOf("Releases:");
		if (releaseIndex == -1) {
			return null;
		}
		output = output.slice(releaseIndex + 1);
		output.reverse();
		final regex = ~/^(.*?) (.*?) (.*?) : (.*?)$/;
		var releases:Array<Release> = [];
		for (line in output) {
			if (!regex.match(line)) {
				continue;
			}
			releases.push({
				date: regex.matched(1),
				time: regex.matched(2),
				version: regex.matched(3),
				releaseNotes: regex.matched(4)
			});
		}
		this.releases[library] = releases;
		return releases;
	}
}

typedef Release = {
	final date:String;
	final time:String;
	final version:String;
	final releaseNotes:String;
}
