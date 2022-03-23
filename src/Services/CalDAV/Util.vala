namespace CalDAVUtil {
    public string get_esource_collection_display_name (E.Source source) {
        var display_name = "";
    
        try {
            var registry = Services.CalDAV.get_default ().get_registry_sync ();
            var collection_source = registry.find_extension (source, E.SOURCE_EXTENSION_COLLECTION);
    
            if (collection_source != null) {
                display_name = collection_source.display_name;
            } else if (source.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
                display_name = ((E.SourceTaskList) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST)).backend_name;
            }
        } catch (Error e) {
            warning (e.message);
        }

        return display_name;
    }
}