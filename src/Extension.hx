import vscode.*;
import Vscode.*;

class Extension {
	@:expose("activate")
	static function activate(context:ExtensionContext) {
		var cwd = workspace.workspaceFolders[0].uri.fsPath;
		trace(haxeshim.Scope.seek({cwd: cwd}).haxeInstallation.compiler);
	}
}
