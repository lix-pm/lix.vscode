import haxe.io.Path;
import tink.core.Promise;

class Util {
	public static function withProgress<T>(title:String, promise:Promise<T>) {
		return window.withProgress({location: Window, title: title}, function(_, _) {
			return new js.lib.Promise((resolve, _) -> {
				promise.handle(_ -> resolve(null));
			});
		});
	}

	public static function normalizePath(path:String):String {
		path = Path.normalize(path);
		var isWindows = Sys.systemName() == "Windows";
		if (isWindows) {
			// c: -> C:
			path = path.substr(0, 1).toUpperCase() + path.substr(1);
		}
		return path;
	}
}
