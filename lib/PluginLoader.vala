internal class Detective.PluginLoader : Object {
    internal SearchProvider[] providers;

    private delegate SearchProvider GetProviderFunc (Module module);

    internal PluginLoader () {}

    construct {
        var base_folder = File.new_for_path (Build.PLUGIN_DIR);
        find_plugins (base_folder);
    }

    private void find_plugins (File base_folder) {
        FileInfo file_info = null;

        try {
            var enumerator = base_folder.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);

            while ((file_info = enumerator.next_file ()) != null) {
                var file = base_folder.get_child (file_info.get_name ());

                if (file_info.get_file_type () == FileType.REGULAR && GLib.ContentType.equals (file_info.get_content_type (), "application/x-sharedlib")) {
                    load (file.get_path ());
                } else if (file_info.get_file_type () == FileType.DIRECTORY) {
                    find_plugins (file);
                }
            }
        } catch (Error error) {
            warning ("Unable to scan plugin folder %s: %s\n", base_folder.get_path (), error.message);
        }
    }

    private void load (string path) {
		if (!Module.supported ()) {
			error ("No module support");
		}

		Module module = Module.open (path, ModuleFlags.LAZY);
		if (module == null) {
			return;
		}

        void* function;
        module.symbol ("get_provider", out function);
		if (function == null) {
			warning ("get_provider () not found");
            return;
		}

        GetProviderFunc get_provider = (GetProviderFunc) function;
		SearchProvider? provider = get_provider (module);

        if (provider == null) {
            return;
        }

        module.make_resident ();

        providers += provider;
	}
}
