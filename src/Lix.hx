class Lix {
	public var scope(default, null):Scope;
	public var switcher(default, null):Switcher;
	public var onDidChangeScope(get, never):Event<Void>;

	final folder:WorkspaceFolder;
	final _onDidChangeScope = new EventEmitter<Void>();

	inline function get_onDidChangeScope()
		return _onDidChangeScope.event;

	public function new(context, folder) {
		this.folder = folder;

		var watcher = workspace.createFileSystemWatcher(new RelativePattern(folder, ".haxerc"));
		watcher.onDidChange(_ -> update());
		watcher.onDidCreate(_ -> update());
		watcher.onDidDelete(_ -> update());
		context.subscriptions.push(watcher);

		update();
	}

	function update() {
		scope = Scope.seek({cwd: folder.uri.fsPath});
		switcher = new Switcher(scope, true, _ -> {});

		// TOOD: check if there were actually any changes?
		_onDidChangeScope.fire();
	}
}
