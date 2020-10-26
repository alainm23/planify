public class Planner.Plugins.Demo : Peas.ExtensionBase, Peas.Activatable {
    public Object object { owned get; construct; }

    public void activate () {
        print ("activate\n");
    }
    
    public void deactivate () {
        print ("deactivate\n");
    }

    public void update_state () { }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (
        typeof (Peas.Activatable),
        typeof (Planner.Plugins.Demo)
    );
}
