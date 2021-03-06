import haxe.io.Path;
import lix.client.haxe.ResolvedVersion.ResolvedUserVersionData;
import tink.CoreApi.Noise;

class HaxeVersionSelector {
	final lix:Lix;
	final vshaxe:Vshaxe;
	final statusBarItem:StatusBarItem;
	var activeEditor:Null<TextEditor>;

	public function new(context, lix, vshaxe) {
		this.lix = lix;
		this.vshaxe = vshaxe;

		statusBarItem = window.createStatusBarItem(Right, 11);
		statusBarItem.tooltip = "Select Haxe Version";
		statusBarItem.command = LixCommand.SelectHaxeVersion;
		context.subscriptions.push(statusBarItem);

		window.onDidChangeActiveTextEditor(editor -> {
			updateActiveEditor(editor);
			updateStatusBarItem();
		});
		lix.onDidChangeScope(_ -> updateStatusBarItem());
		vshaxe.haxeExecutable.onDidChangeConfiguration(_ -> updateStatusBarItem());

		updateActiveEditor(window.activeTextEditor);
		updateStatusBarItem();
	}

	function updateActiveEditor(activeEditor:Null<TextEditor>) {
		if (activeEditor != null && activeEditor.document.uri.scheme == "output") {
			return; // ignore focusing the output channel "document"
		}
		this.activeEditor = activeEditor;
	}

	function updateStatusBarItem() {
		var isHaxeFile = false;
		if (activeEditor != null) {
			var languageId = activeEditor.document.languageId;
			if (languageId == "haxe" || languageId == "hxml") {
				isHaxeFile = true;
			} else if (Path.withoutDirectory(activeEditor.document.uri.path) == ".haxerc") {
				isHaxeFile = true;
			}
		}
		if (lix.active && isHaxeFile && didProvideExecutable()) {
			statusBarItem.text = lix.haxeVersion;
			statusBarItem.show();
		} else {
			statusBarItem.hide();
		}
	}

	function didProvideExecutable() {
		return vshaxe.haxeExecutable.configuration.source.match(Provider("lix"));
	}

	public function selectHaxeVersion() {
		if (!didProvideExecutable()) {
			window.showErrorMessage('The Haxe executable is currently not controlled by lix. Maybe "haxe.executable" is not set to "auto"?');
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
				for (path in lix.getCustomHaxeDirectories()) {
					items.push({
						label: path,
						select: switchToVersion.bind(RCustom(path))
					});
				}
				for (item in items) {
					if (item.label == lix.haxeVersion) {
						item.description = "selected";
					}
				}
				items.push({
					label: "From directory...",
					select: switchToDirectory
				});
				items.push({
					label: "Install another version...",
					select: installAnotherVersion.bind(items.map(item -> item.label))
				});

				showSelectableQuickPick(items, "Select an Installed Haxe Version to Switch to");
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
					lix.switcher.switchTo(data).eager();
				case Failure(_):
			}
			return Noise;
		});
	}

	function switchToDirectory() {
		window.showOpenDialog({canSelectFiles: false, canSelectFolders: true}).then(function(uris) {
			if (uris != null && uris.length > 0) {
				var path = Util.normalizePath(uris[0].fsPath);
				if (Util.containsHaxeExecutable(path)) {
					lix.switcher.switchTo(RCustom(path)).eager();
				} else {
					window.showErrorMessage('No Haxe executable found in $path', "Retry", "Close").then(choice -> {
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
			showSelectableQuickPick(items, "Select Version to Download and Switch to");
		});
	}

	function installVersion(version:String, force:Bool) {
		Util.withProgress('Installing Haxe $version...', lix.switcher.install(version, {force: false}));
	}
}

private typedef SelectableQuickPickItem = QuickPickItem & {
	var select:() -> Void;
}
