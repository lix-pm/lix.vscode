import tink.CoreApi.Noise;
import lix.client.haxe.ResolvedVersion.ResolvedUserVersionData;

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

	function selectHaxeVersion() {
		switcher.officialInstalled(IncludePrereleases)
			.handle(official -> {
				switcher.nightliesInstalled()
					.handle(nightlies -> {
						var items:Array<HaxeVersionItem> = [];
						switch official {
							case Success(data):
								for (version in data) {
									items.push({
										label: version,
										data: ROfficial(version)
									});
								}
							case Failure(_):
						}
						switch nightlies {
							case Success(data):
								for (version in data) {
									items.push({
										label: version.hash,
										data: RNightly(version)
									});
								}
							case Failure(_):
						}
						window.showQuickPick(items, {placeHolder: "Select .haxerc Haxe version"})
							.then(version -> {
								if (version != null) {
									switcher.resolveInstalled(version.data)
										.handle(resolved -> {
											switch resolved {
												case Success(data):
													switcher.switchTo(data);
												case Failure(_):
											}
											return Noise;
										});
								}
							});
					});
			});
	}
}

private typedef HaxeVersionItem = QuickPickItem & {
	var data:ResolvedUserVersionData;
}
