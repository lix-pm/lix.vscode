class Extension {
	@:expose("activate")
	static function activate(context:ExtensionContext) {
		var folders = workspace.workspaceFolders;
		if (folders.length == 0) {
			return;
		}

		var lix = new Lix(context, folders[0]);
		new HaxeVersionSelector(context, lix);
	}
}
