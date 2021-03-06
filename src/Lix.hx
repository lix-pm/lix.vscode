import haxe.Json;
import haxe.io.Path;
import haxeshim.Config;
import haxeshim.Logger;
import js.node.Buffer;
import js.node.ChildProcess;
import js.node.child_process.ChildProcess.ChildProcessEvent;
import js.node.stream.Readable.ReadableEvent;
import sys.FileSystem;
import sys.io.File;
import tink.CoreApi;

class Lix {
	static inline final CUSTOM_HAXE_DIRECTORIES_KEY = "customHaxeDirectories";

	public var active(default, null):Bool;
	public var scope(default, null):Scope;
	public var switcher(default, null):Switcher;
	public var onDidChangeScope(get, never):Event<Void>;
	public var haxeVersion(get, never):String;

	var outputChannel:Null<OutputChannel>;
	var config:Null<Config>;

	final context:ExtensionContext;
	final folder:WorkspaceFolder;
	final _onDidChangeScope = new EventEmitter<Void>();

	inline function get_onDidChangeScope()
		return _onDidChangeScope.event;

	inline function get_haxeVersion()
		return Util.normalizePath(scope.haxeInstallation.version);

	public function new(context, folder) {
		this.context = context;
		this.folder = folder;

		haxe.Log.trace = (v, ?infos) -> appendToOutputChannel(Std.string(v));

		var watcher = workspace.createFileSystemWatcher(new RelativePattern(folder, ".haxerc"));
		watcher.onDidChange(_ -> update());
		watcher.onDidCreate(_ -> update());
		watcher.onDidDelete(_ -> update());
		context.subscriptions.push(watcher);

		update();
	}

	function appendToOutputChannel(line:String) {
		if (outputChannel != null) {
			outputChannel.appendLine(line);
		}
	}

	function update() {
		var file = Path.join([folder.uri.fsPath, ".haxerc"]);
		active = FileSystem.exists(file);

		var newConfig = if (active) Json.parse(File.getContent(file)) else null;
		if (config != null && Json.stringify(config) == Json.stringify(newConfig)) {
			return; // no changes
		}
		config = newConfig;

		scope = Scope.seek({cwd: folder.uri.fsPath});

		switcher = new Switcher(scope, new OutputChannelLogger(appendToOutputChannel));

		if (active) {
			if (outputChannel == null) {
				outputChannel = window.createOutputChannel("lix");
			}
		} else {
			if (outputChannel != null) {
				outputChannel.dispose();
				outputChannel = null;
			}
		}

		var version = haxeVersion;
		if (Util.isPath(version)) {
			var paths = getCustomHaxeDirectories();
			if (!paths.contains(version)) {
				setCustomHaxeDirectories(paths.concat([version]));
			}
		}

		commands.executeCommand("setContext", "lixActive", active);
		_onDidChangeScope.fire();
	}

	public function run(command:Array<String>) {
		var commandString = 'lix ${command.join(" ")}';
		Util.withProgress('$commandString...', new Promise(function(resolve, reject) {
			trace('> npx $commandString');
			var childProcess = ChildProcess.spawn("npx", ["lix"].concat(command), {cwd: folder.uri.fsPath, shell: true});
			function print(buffer:Buffer) {
				var s = buffer.toString().trim();
				if (s != "") {
					trace(s);
				}
			}
			childProcess.stdout.on(ReadableEvent.Data, print);
			childProcess.stderr.on(ReadableEvent.Data, print);
			childProcess.on(ChildProcessEvent.Exit, (code, _) -> {
				resolve(Noise);
				trace('Exited with $code.');
				if (code != 0) {
					window.showErrorMessage('"$commandString" failed with exit code $code', "Show Output", "Close").then(function(choice) {
						if (choice != null && choice == "Show Output") {
							outputChannel.show();
						}
					});
				}
			});
		}, true));
	}

	public function getCustomHaxeDirectories():Array<String> {
		var paths = context.globalState.get(CUSTOM_HAXE_DIRECTORIES_KEY, []);
		var filteredPaths = paths.filter(Util.containsHaxeExecutable);
		if (paths.length != filteredPaths.length) {
			setCustomHaxeDirectories(filteredPaths);
		}
		return filteredPaths;
	}

	function setCustomHaxeDirectories(directories:Array<String>) {
		context.globalState.update(CUSTOM_HAXE_DIRECTORIES_KEY, directories);
	}
}

private class OutputChannelLogger extends Logger {
	final appendToOutputChannel:String->Void;

	public function new(appendToOutputChannel) {
		super();
		this.appendToOutputChannel = appendToOutputChannel;
	}

	override function error(s:String) {
		appendToOutputChannel('[error] $s');
	}

	override function info(s:String) {
		appendToOutputChannel('[info] $s');
	}

	override function warning(s:String) {
		appendToOutputChannel('[warning] $s');
	}

	override function progress(s:String) {
		appendToOutputChannel('[progress] $s');
	}

	override function success(s:String) {
		appendToOutputChannel('[success] $s');
	}
}
