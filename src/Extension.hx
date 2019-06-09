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

		new HaxeVersionSelector(context, lix, vshaxe);
		new Commands(folder, lix);

		var provider = new HaxeInstallationProvider(folder, lix);
		var providerDisposable:Disposable;

		function updateHaxeInstallation() {
			if (lix.scope.isGlobal) {
				if (providerDisposable != null) {
					providerDisposable.dispose();
					providerDisposable = null;
				}
			} else {
				if (providerDisposable == null) {
					providerDisposable = vshaxe.registerHaxeInstallationProvider("lix", provider);
				}
			}
		}
		updateHaxeInstallation();

		lix.onDidChangeScope(_ -> updateHaxeInstallation());
	}
}
