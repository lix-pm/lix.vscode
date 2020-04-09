class LibraryCacheGuard {
	public function new(lix:Lix) {
		var warned = new Map<String, Bool>();
		var watcher = workspace.createFileSystemWatcher("**/*.*", true, false, true);
		watcher.onDidChange(function(uri) {
			var path = Util.normalizePath(uri.fsPath);
			if (warned[path]) {
				return;
			}
			warned[path] = true;
			var libCache = Util.normalizePath(lix.scope.libCache);
			var versionDir = Util.normalizePath(lix.scope.versionDir);
			if (path.startsWith(libCache) || path.startsWith(versionDir)) {
				window.showWarningMessage("It is strongly recommended not to edit files in the lix library cache. It can result in a non-reproducible setup.",
					{modal: true});
			}
		});
	}
}
