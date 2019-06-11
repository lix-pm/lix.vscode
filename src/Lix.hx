import js.node.Buffer;
import js.node.stream.Readable.ReadableEvent;
import js.node.ChildProcess;
import js.node.child_process.ChildProcess.ChildProcessEvent;
import tink.CoreApi;
import haxeshim.Logger;

class Lix {
	public var scope(default, null):Scope;
	public var switcher(default, null):Switcher;
	public var onDidChangeScope(get, never):Event<Void>;

	final outputChannel:OutputChannel;
	final folder:WorkspaceFolder;
	final _onDidChangeScope = new EventEmitter<Void>();

	inline function get_onDidChangeScope()
		return _onDidChangeScope.event;

	public function new(context, folder) {
		this.folder = folder;

		outputChannel = window.createOutputChannel("lix");
		haxe.Log.trace = (v, ?infos) -> outputChannel.appendLine(Std.string(v));

		var watcher = workspace.createFileSystemWatcher(new RelativePattern(folder, ".haxerc"));
		watcher.onDidChange(_ -> update());
		watcher.onDidCreate(_ -> update());
		watcher.onDidDelete(_ -> update());
		context.subscriptions.push(watcher);

		update();
	}

	function update() {
		scope = Scope.seek({cwd: folder.uri.fsPath});
		@:privateAccess scope.logger = new OutputChannelLogger(outputChannel);
		switcher = new Switcher(scope, true, outputChannel.appendLine);

		if (scope.isGlobal) {
			outputChannel.hide();
		} else {
			outputChannel.show();
		}

		// TOOD: check if there were actually any changes?
		_onDidChangeScope.fire();
	}

	public function run(command:Array<String>) {
		Util.withProgress('lix ${command.join(" ")}...', new Promise(function(resolve, reject) {
			trace('> npx lix ${command.join(" ")}');
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
			});
		}, true));
	}
}

private class OutputChannelLogger extends Logger {
	final outputChannel:OutputChannel;

	public function new(outputChannel:OutputChannel) {
		super();
		this.outputChannel = outputChannel;
	}

	override function error(s:String) {
		outputChannel.appendLine('[error] $s');
	}

	override function info(s:String) {
		outputChannel.appendLine('[info] $s');
	}

	override function warning(s:String) {
		outputChannel.appendLine('[warning] $s');
	}

	override function progress(s:String) {
		outputChannel.appendLine('[progress] $s');
	}

	override function success(s:String) {
		outputChannel.appendLine('[success] $s');
	}
}
