class Lix {
	public var scope(default, null):Scope;
	public var switcher(default, null):Switcher;

	final folder:WorkspaceFolder;

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
	}
}
