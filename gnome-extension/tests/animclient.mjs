// Test helper: a tiny always-animating Wayland client. Continuous damage
// forces the compositor's frame clock to tick, which headless clean-room
// sessions need for animations and screenshot captures to progress.
import Gtk from 'gi://Gtk?version=4.0';
import GLib from 'gi://GLib';

Gtk.init();

const win = new Gtk.Window({
    title: 'pqv-animclient',
    defaultWidth: 260,
    defaultHeight: 120,
});
const label = new Gtk.Label({label: '0'});
win.setChild(label);
win.connect('notify::mapped', () => {
    if (win.mapped)
        print('ANIMCLIENT MAPPED');
});
let frame = 0;
GLib.timeout_add(GLib.PRIORITY_DEFAULT, 16, () => {
    label.label = `frame ${++frame}`;
    return GLib.SOURCE_CONTINUE;
});
win.present();
GLib.MainLoop.new(null, false).run();
