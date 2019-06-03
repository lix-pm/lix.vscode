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

		new HaxeVersionSelector(context, scope, switcher);
	}
}
