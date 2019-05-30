import vscode.*;
import Vscode.*;
import lix.client.haxe.Switcher;
import haxeshim.Scope;

using Lambda;

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
		switcher.officialInstalled(IncludePrereleases).map(o -> {
			switch o {
				case Success(data):
					trace(data.array());
				case Failure(failure):
					trace(failure);
			}
		});
		Switcher.officialOnline(IncludePrereleases).map(o -> {
			switch o {
				case Success(data):
					trace(data.array());
				case Failure(failure):
					trace(failure);
			}
		});
	}
}
