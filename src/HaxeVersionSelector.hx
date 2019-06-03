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
		switcher.officialInstalled(IncludePrereleases).handle(official -> {
			switcher.nightliesInstalled().handle(nightlies -> {
				var items:Array<SelectableQuickPickItem> = [];
				switch official {
					case Success(data):
						for (version in data) {
							items.push({
								label: version,
								select: switchToVersion.bind(ROfficial(version))
							});
						}
					case Failure(_):
				}
				switch nightlies {
					case Success(data):
						for (version in data) {
							items.push({
								label: version.hash,
								select: switchToVersion.bind(RNightly(version))
							});
						}
					case Failure(_):
				}
				items.push({
					label: "Install another version...",
					select: installAnotherVersion
				});

				showSelectableQuickPick(items, "Select an installed Haxe version to switch to");
			});
		});
	}

	function showSelectableQuickPick(items:Array<SelectableQuickPickItem>, placeHolder:String) {
		window.showQuickPick(items, {placeHolder: placeHolder}).then(item -> if (item != null) item.select());
	}

	function switchToVersion(version:ResolvedUserVersionData) {
		switcher.resolveInstalled(version).handle(resolved -> {
			switch resolved {
				case Success(data):
					switcher.switchTo(data);
				case Failure(_):
			}
			return Noise;
		});
	}

	function installAnotherVersion() {
		Switcher.officialOnline(IncludePrereleases).handle(official -> {
			var items:Array<SelectableQuickPickItem> = [];
			switch official {
				case Success(data):
					for (version in data) {
						items.push({
							label: version,
							select: function() {
								window.withProgress({location: Window, title: 'Installing Haxe $version...'}, function(_, _) {
									return new js.lib.Promise((resolve, _) -> {
										switcher.install(version, {force: false}).handle(_ -> resolve(null));
									});
								});
							}
						});
					}
				case Failure(_):
			}
			showSelectableQuickPick(items, "Select version to download and switch to");
		});
	}
}

private typedef SelectableQuickPickItem = QuickPickItem & {
	var select:() -> Void;
}
