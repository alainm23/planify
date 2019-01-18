from gi.overrides import override
from gi.importer import modules

Dee = modules['Dee']._introspection_module
from gi.repository import GLib

__all__ = []

class RowWrapper:
    def __init__ (self, model, itr):
        self.model = model
        self.itr = itr
        self.__initialized = True
    
    def __getitem__ (self, column):
        return self.model.get_value(self.itr, column)
    
    def __setitem__ (self, column, val):
        self.model.set_value (self.itr, column, val)
    
    def __getattr__ (self, name):
        col_index = self.model.get_column_index (name)
        if col_index < 0:
            raise AttributeError("object has no attribute '%s'" % name)
        return self.model.get_value (self.itr, col_index)
    
    def __setattr__ (self, name, value):
        if not "_RowWrapper__initialized" in self.__dict__:
            self.__dict__[name] = value
            return
        col_index = self.model.get_column_index (name)
        if col_index < 0:
            raise AttributeError("object has no attribute '%s'" % name)
        self.model.set_value (self.itr, col_index, value)
    
    def __iter__ (self):
        for column in range(self.model.get_n_columns()):
            yield self.model.get_value (self.itr, column)
    
    def __len__ (self):
        return self.model.get_n_columns()
    
    def __str__ (self):
        return "(%s)" % ", ".join(map(str,self))
    
    def __eq__ (self, other):
        if not isinstance (other, RowWrapper):
            return False
        if self.model != other.model:
            return False
        return self.itr == other.itr

class Model(Dee.Model):

    def __init__(self):
        Dee.Model.__init__(self)

    def set_schema (self, *args):
        self.set_schema_full (tuple(args))
    
    def set_column_names (self, *args):
        self.set_column_names_full (tuple(args))

    def _build_row (self, args, kwargs):
        schema = self.get_schema()
        result = [None] * len(schema)
        if len(args) > 0:
            for i, arg in enumerate(args):
                if isinstance(arg, GLib.Variant):
                    result[i] = arg
                else:
                    result[i] = GLib.Variant(schema[i], arg)

            # check
            if result.count(None) > 0:
                raise RuntimeError("Not all columns were set")
        else:
            names = self.get_column_names()
            dicts = [None] * len(schema)
            if len(names) == 0:
                raise RuntimeError("Column names were not set")
            for col_name, arg in kwargs.items():
                if names.count(col_name) > 0:
                    col_index = names.index(col_name)
                    variant = arg if isinstance(arg, GLib.Variant) else GLib.Variant(schema[col_index], arg)
                    result[col_index] = variant
                else:
                    col_schema, col_index = self.get_field_schema(col_name)
                    if col_schema:
                        variant = arg if isinstance(arg, GLib.Variant) else GLib.Variant(col_schema, arg)
                        colon_index = col_name.find("::")
                        field_name = col_name if colon_index < 0 else col_name[colon_index+2:]
                        if dicts[col_index] is None: dicts[col_index] = {}
                        dicts[col_index][field_name] = variant
                    else:
                        raise RuntimeError("Unknown column name: %s" % col_name)

            # finish vardict creation
            for index, d in enumerate(dicts):
                if d: result[index] = GLib.Variant(schema[index], d)

            # handle empty dicts (no "xrange" in python3)
            for i in range(len(schema)):
                if result[i] is None and schema[i] == "a{sv}":
                    result[i] = GLib.Variant(schema[i], {})

            # checks
            num_unset = result.count(None)
            if num_unset > 0:
                col_name = names[result.index(None)]
                raise RuntimeError("Column '%s' was not set" % col_name)

        return result
    
    def prepend (self, *args, **kwargs):
        return self.prepend_row (self._build_row(args, kwargs))
    
    def append (self, *args, **kwargs):
        return self.append_row (self._build_row(args, kwargs))
    
    def insert (self, pos, *args, **kwargs):
        return self.insert_row (pos, self._build_row(args, kwargs))
    
    def insert_before (self, iter, *args, **kwargs):
        return self.insert_row_before (iter, self._build_row(args, kwargs))
    
    def insert_row_sorted (self, row_spec, sort_func, data):
    	return self.insert_row_sorted_with_sizes (row_spec, sort_func, data)

    def insert_sorted (self, sort_func, *args, **kwargs):
    	return self.insert_row_sorted (self._build_row(args, kwargs), sort_func, None)
   
    def find_row_sorted (self, row_spec, sort_func, data):
    	return self.find_row_sorted_with_sizes (row_spec, sort_func, data)
    
    def find_sorted (self, sort_func, *args, **kwargs):
    	return self.find_row_sorted (self._build_row(args, kwargs), sort_func, None)
    
    def get_schema (self):
        return Dee.Model.get_schema(self)
    
    def get_value (self, itr, column):
        return Dee.Model.get_value (self, itr, column).unpack()
    
    def set_value (self, itr, column, value):
        var = GLib.Variant (self.get_column_schema(column), value)
        if isinstance (itr, int):
            itr = self.get_iter_at_row(itr)
        Dee.Model.set_value (self, itr, column, var)
    
    def __getitem__ (self, itr):
        if isinstance (itr, int):
            itr = self.get_iter_at_row(itr)
        return RowWrapper(self, itr)
    
    def __setitem__ (self, itr, row):
        max_col = self.get_n_columns ()
        for column, value in enumerate (row):
            if column >= max_col:
                raise IndexError("Too many columns in row assignment: %s" % column)
            self.set_value (itr, column, value)
    
    def get_row (self, itr):
        return self[itr]
    
    def __iter__ (self):
        itr = self.get_first_iter ()
        last = self.get_last_iter ()
        while itr != last:
            yield self.get_row(itr)
            itr = self.next(itr)
        raise StopIteration
    
    def __len__ (self):
        return self.get_n_rows()
        
        
class ModelIter(Dee.ModelIter):

    def __init__(self):
        Dee.ModelIter.__init__(self)

    def __eq__ (self, other):
        if not isinstance (other, ModelIter):
            return False
        return repr(self) == repr(other)



Model = override(Model)
__all__.append('Model')
ModelIter = override(ModelIter)
__all__.append('ModelIter')


