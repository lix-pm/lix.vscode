class Extension {
	@:expose("activate")
	static function activate(context:ExtensionContext) {
		var folders = workspace.workspaceFolders;
		if (folders.length == 0) {
			return;
		}
		var cwd = folders[0].uri.fsPath;
		var scope = Scope.seek({cwd: cwd});
		var switcher = new Switcher(scope, true, _ -> {});

		var versionSelector = new HaxeVersionSelector(context, cwd, switcher);

		var watcher = workspace.createFileSystemWatcher(new RelativePattern(folders[0], ".haxerc"));
		watcher.onDidChange(_ -> versionSelector.updateStatusBarItem());
		watcher.onDidCreate(_ -> versionSelector.updateStatusBarItem());
		watcher.onDidDelete(_ -> versionSelector.updateStatusBarItem());
		context.subscriptions.push(watcher);
	}
}
