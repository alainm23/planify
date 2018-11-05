public class Dialogs.SettingsDialog : Gtk.Dialog {
    public weak MainWindow window { get; construct; }
    private Gtk.Stack main_stack;

    public SettingsDialog (MainWindow parent) {
		Object (
			border_width: 5,
			deletable: false,
			resizable: false,
			title: _("Preferences"),
			transient_for: parent,
			window: parent
		);
	}

    construct {

    }
}
