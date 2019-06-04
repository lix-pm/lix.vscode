import sys.FileSystem;
import tink.CoreApi.Noise;
import lix.client.haxe.ResolvedVersion.ResolvedUserVersionData;

class HaxeVersionSelector {
	final lix:Lix;
	final statusBarItem:StatusBarItem;

	public function new(context, lix) {
		this.lix = lix;

		statusBarItem = window.createStatusBarItem(Right, 11);
		statusBarItem.tooltip = "Select Haxe Version";
		statusBarItem.command = LixCommand.SelectHaxeVersion;
		context.subscriptions.push(statusBarItem);

		window.onDidChangeActiveTextEditor(_ -> updateStatusBarItem());
		lix.onDidChangeScope(_ -> updateStatusBarItem());

		commands.registerCommand(LixCommand.SelectHaxeVersion, selectHaxeVersion);

		updateStatusBarItem();
	}

	function updateStatusBarItem() {
		var activeEditor = window.activeTextEditor;
		if (activeEditor == null || activeEditor.document.languageId != "haxe" || lix.scope.isGlobal) {
			statusBarItem.hide();
			return;
		}
		statusBarItem.text = lix.scope.haxeInstallation.version;
		statusBarItem.show();
	}

	function selectHaxeVersion() {
		if (lix.scope.isGlobal) {
			// TODO: offer to create one
			window.showErrorMessage("No .haxerc / local scope found.");
			return;
		}
		lix.switcher.officialInstalled(IncludePrereleases).handle(official -> {
			lix.switcher.nightliesInstalled().handle(nightlies -> {
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
					label: "From directory...",
					select: switchToDirectory
				});
				items.push({
					label: "Install another version...",
					select: installAnotherVersion.bind(items.map(item -> item.label))
				});

				showSelectableQuickPick(items, "Select an installed Haxe version to switch to");
			});
		});
	}

	function showSelectableQuickPick(items:Array<SelectableQuickPickItem>, placeHolder:String) {
		window.showQuickPick(items, {placeHolder: placeHolder}).then(item -> if (item != null) item.select());
	}

	function switchToVersion(version:ResolvedUserVersionData) {
		lix.switcher.resolveInstalled(version).handle(resolved -> {
			switch resolved {
				case Success(data):
					lix.switcher.switchTo(data);
				case Failure(_):
			}
			return Noise;
		});
	}

	function switchToDirectory() {
		window.showOpenDialog({canSelectFiles: false, canSelectFolders: true})
			.then(function(uris) {
				if (uris != null && uris.length > 0) {
					var path = uris[0].fsPath;
					var isWindows = Sys.systemName() == "Windows";
					if (isWindows) {
						// c: -> C:
						path = path.substr(0, 1)
							.toUpperCase() + path.substr(1);
					}
					var haxe = '$path/haxe' + (if (isWindows) ".exe" else "");
					if (FileSystem.exists(haxe)) {
						lix.switcher.switchTo(RCustom(path))
							.eager();
					} else {
						window.showErrorMessage('"$haxe" does not exist', "Retry", "Close")
							.then(choice -> {
								if (choice == "Retry") {
									switchToDirectory();
								}
							});
					}
				}
			});
	}

	function installAnotherVersion(installed:Array<String>) {
		Switcher.officialOnline(IncludePrereleases).handle(official -> {
			var items:Array<SelectableQuickPickItem> = [];
			items.push({
				label: "latest",
				description: "the latest release of Haxe (including preview releases)",
				select: installVersion.bind("latest", true)
			});
			items.push({
				label: "stable",
				description: "the latest stable release of Haxe",
				select: installVersion.bind("stable", true)
			});
			items.push({
				label: "nightly",
				description: "the latest nightly build of Haxe",
				select: installVersion.bind("nightly", true)
			});
			switch official {
				case Success(data):
					for (version in data) {
						items.push({
							label: version,
							description: if (installed.indexOf(version) == -1) "" else "installed",
							select: installVersion.bind(version, false)
						});
					}
				case Failure(_):
			}
			showSelectableQuickPick(items, "Select version to download and switch to");
		});
	}

	function installVersion(version:String, force:Bool) {
		window.withProgress({location: Window, title: 'Installing Haxe $version...'}, function(_, _) {
			return new js.lib.Promise((resolve, _) -> {
				lix.switcher.install(version, {force: false}).handle(_ -> resolve(null));
			});
		});
	}
}

private typedef SelectableQuickPickItem = QuickPickItem & {
	var select:() -> Void;
}
