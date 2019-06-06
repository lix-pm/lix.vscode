import tink.core.Promise;

class Util {
	public static function withProgress<T>(title:String, promise:Promise<T>) {
		return window.withProgress({location: Window, title: title}, function(_, _) {
			return new js.lib.Promise((resolve, _) -> {
				promise.handle(_ -> resolve(null));
			});
		});
	}
}
