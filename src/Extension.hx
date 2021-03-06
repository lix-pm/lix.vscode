class Extension {
	@:expose("activate")
	static function activate(context:ExtensionContext) {
		var folders = workspace.workspaceFolders;
		if (folders.length == 0) {
			return;
		}
		var folder = folders[0];

		var lix = new Lix(context, folder);
		var vshaxe:Vshaxe = extensions.getExtension("nadako.vshaxe").exports;
		var installation = new HaxeInstallationProvider(folder, lix, vshaxe);
		var haxelib = new Haxelib(folder, installation);
		var selector = new HaxeVersionSelector(context, lix, vshaxe);
		new Commands(folder, lix, haxelib, selector);
		new LibraryCacheGuard(lix);
	}
}
