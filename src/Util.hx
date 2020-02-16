import haxe.io.Path;
import tink.core.Promise;
import sys.FileSystem;

class Util {
	public static function withProgress<T>(title:String, promise:Promise<T>) {
		return window.withProgress({location: Window, title: title}, function(_, _) {
			return new js.lib.Promise((resolve, _) -> {
				promise.handle(_ -> resolve(null));
			});
		});
	}

	public static function normalizePath(s:String):String {
		if (!isPath(s)) {
			return s;
		}
		var path = Path.normalize(s);
		var isWindows = Sys.systemName() == "Windows";
		if (isWindows) {
			// c: -> C:
			path = path.substr(0, 1).toUpperCase() + path.substr(1);
		}
		return path;
	}

	public static function isPath(s:String):Bool {
		return s.contains("/") || s.contains("\\");
	}

	public static function containsHaxeExecutable(dir:String):Bool {
		var isWindows = Sys.systemName() == "Windows";
		var haxe = '$dir/haxe' + (if (isWindows) ".exe" else "");
		return FileSystem.exists(haxe);
	}
}
