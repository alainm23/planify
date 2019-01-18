from gi.overrides import override
from gi.importer import modules
import threading
import sys

Unity = modules['Unity']._introspection_module
from gi.repository import GLib

__all__ = []

class ScopeSearchBase(Unity.ScopeSearchBase):

    def __init__(self):
        Unity.ScopeSearchBase.__init__(self)

    def do_run_async(self, callback, callback_data=None):
        def thread_method():
            try:
                self.run()
            finally:
                callback(self)

        t = threading.Thread(target=thread_method, name="python-search-thread")
        t.start()


class ResultPreviewer(Unity.ResultPreviewer):

    def __init__(self):
        Unity.ResultPreviewer.__init__(self)

    def do_run_async(self, callback, callback_data=None):
        def thread_method():
            preview = None
            try:
                preview = self.run()
            finally:
                callback(self, preview)

        t = threading.Thread(target=thread_method, name="python-preview-thread")
        t.start()


class ResultSet(Unity.ResultSet):

    def __init__ (self):
        Unity.ResultSet.__init__(self)

    def add_result(self, *args, **kwargs):
        if len(args) > 0:
            Unity.ResultSet.add_result(self, *args)
        elif len(kwargs) > 0:
            result = kwargs_to_result_variant(**kwargs)
            Unity.ResultSet.add_result_from_variant(self, result)


def kwargs_to_result_variant(**kwargs):
    uri = None
    icon = ""
    category = 0
    result_type = 0
    mimetype = None
    title = None
    comment = ""
    dnd_uri = None
    metadata = {}

    for col_name, value in kwargs.items():
        if col_name == "uri": uri = value
        elif col_name == "icon": icon = value
        elif col_name == "category": category = value
        elif col_name == "result_type": result_type = value
        elif col_name == "mimetype": mimetype = value
        elif col_name == "title": title = value
        elif col_name == "comment": comment = value
        elif col_name == "dnd_uri": dnd_uri = value
        else:
            if isinstance(value, GLib.Variant):
                metadata[col_name] = value
            elif isinstance(value, str):
                metadata[col_name] = GLib.Variant("s", value)
            elif isinstance(value, int):
                metadata[col_name] = GLib.Variant("i", value)
            elif sys.version_info < (3, 0, 0):
                # unicode is not defined in py3
                if isinstance(value, unicode):
                    metadata[col_name] = GLib.Variant("s", value)

    result = GLib.Variant("(ssuussssa{sv})", (uri, icon, category,
                                              result_type, mimetype,
                                              title, comment, dnd_uri,
                                              metadata))
    return result


def dict_to_variant(metadata_dict):
    metadata = {}

    for name, value in metadata_dict.items():
        if isinstance(value, GLib.Variant):
            metadata[name] = value
        elif isinstance(value, str):
            metadata[name] = GLib.Variant("s", value)
        elif isinstance(value, int):
            metadata[name] = GLib.Variant("i", value)
        elif sys.version_info < (3, 0, 0):
            # unicode is not defined in py3
            if isinstance(value, unicode):
                metadata[name] = GLib.Variant("s", value)

    return GLib.Variant("a{sv}", metadata)


class ScopeResult(Unity.ScopeResult):

    @staticmethod
    def create(*args, **kwargs):
        if len(kwargs) > 0:
            result = kwargs_to_result_variant(**kwargs)
            return Unity.ScopeResult.create_from_variant(result)
        return Unity.ScopeResult.create(*args)


class SearchContext(Unity.SearchContext):

    @staticmethod
    def create(search_query, search_type, filter_state, metadata_dict, result_set, cancellable):
        context = Unity.SearchContext.create(search_query, search_type, filter_state, None, result_set, cancellable)
        if metadata_dict and len(metadata_dict) > 0:
            metadata_variant = dict_to_variant(metadata_dict)
            context.set_search_metadata(Unity.SearchMetadata.create_from_variant(metadata_variant))

        return context

ScopeSearchBase = override(ScopeSearchBase)
__all__.append('ScopeSearchBase')
ResultPreviewer = override(ResultPreviewer)
__all__.append('ResultPreviewer')
ResultSet = override(ResultSet)
__all__.append('ResultSet')
ScopeResult = override(ScopeResult)
__all__.append('ScopeResult')
SearchContext = override(SearchContext)
__all__.append('SearchContext')
