<div align="center">
  <span align="center"> <img width="80" height="80" class="center" src="https://raw.githubusercontent.com/alainm23/planner/master/data/icons/hicolor/scalable/apps/com.github.alainm23.task-planner.svg" alt="Icon"></span>
  <h1 align="center">Planify</h1>
  <h3 align="center">Never worry about forgetting things again</h3>
</div>

![Planify Screenshot](https://raw.githubusercontent.com/alainm23/planner/master/data/resources/screenshot/screenshot-01.png)

## Planify is here...

- 🚀️ Neat visual style.
- 🤚️ Drag and Order: Sort your tasks wherever you want.
- 💯️ Progress indicator for each project.
- 💪️ Be more productive and organize your tasks by 'Sections'.
- 📅️ Visualize your events and plan your day better.
- ⏲️ Reminder system, you can create one or more reminders, you decide.
- 🌙️ Better integration with the dark theme.
- 🎉️ and much more.

### ☁️ Support for Todoist:

- Synchronize your Projects, Task and Sections thanks to Todoist.
- Support for Todoist offline: Work without an internet connection and when everything is reconnected it will be synchronized.
- Planify not created by, affiliated with, or supported by Doist

### 💎️ Other features:

- ⏲️ Reminders notifications.
- 🔍️ Quick Find.
- 🌙️ Night mode.
- 🔁️ Recurring due dates.

### Flathub Beta
```
flatpak remote-add flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak install io.github.alainm23.planify
```

## 🛠 Compile

You'll need the following dependencies:

* gtk4
* libadwaita

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.github.alainm23.planify`

    sudo ninja install
    io.github.alainm23.planify

## Support
If you like Planify and you want to support its development, consider supporting via [Patreon](https://www.patreon.com/alainm23), [PayPal](https://www.paypal.me/alainm23) or [Liberapay](https://liberapay.com/Alain)

Made with 💗 in Perú
