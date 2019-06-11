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
