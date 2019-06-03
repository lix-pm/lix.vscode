class HaxeVersionSelector {
	static inline var Command = "lix.selectHaxeVersion";

	var scope:Scope;
	var switcher:Switcher;
	var statusBarItem:StatusBarItem;

	public function new(context, scope, switcher) {
		this.scope = scope;
		this.switcher = switcher;

		statusBarItem = window.createStatusBarItem(Right, 11);
		statusBarItem.tooltip = "Select Haxe Version";
		statusBarItem.command = Command;
		context.subscriptions.push(statusBarItem);

		window.onDidChangeActiveTextEditor(_ -> updateStatusBarItem());
		commands.registerCommand(Command, selectHaxeVersion);

		updateStatusBarItem();
	}

	function updateStatusBarItem() {
		var activeEditor = window.activeTextEditor;
		if (activeEditor == null || activeEditor.document.languageId != "haxe") {
			statusBarItem.hide();
			return;
		}
		statusBarItem.text = scope.haxeInstallation.version;
		statusBarItem.show();
	}

	function selectHaxeVersion() {}
}
