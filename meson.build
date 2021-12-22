project ('com.github.alainm23.planner', 'vala', 'c')

gnome = import ('gnome')
i18n = import ('i18n')

add_global_arguments ('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()), language:'c')

asresources = gnome.compile_resources (
    'as-resources', 'data/' + meson.project_name () + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
config_header = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

executable (
    meson.project_name (),
    'src/Util.vala',
    'src/Application.vala',
    'src/MainWindow.vala',
    
    'src/Layouts/Sidebar.vala',
    'src/Layouts/FilterPaneRow.vala',
    'src/Layouts/HeaderItem.vala',
    'src/Layouts/LabelRow.vala',
    'src/Layouts/ItemRow.vala',
    'src/Layouts/ProjectRow.vala',
    'src/Layouts/ViewHeader.vala',
    'src/Layouts/SectionRow.vala',
    'src/Layouts/LabelChild.vala',

    'src/Widgets/DynamicIcon.vala',
    'src/Widgets/TodoistSync.vala',
    'src/Widgets/ProjectProgress.vala',
    'src/Widgets/EditableLabel.vala',
    'src/Widgets/TopHeaderProject.vala',
    'src/Widgets/ColorPopover.vala',
    'src/Widgets/MagicButton.vala',
    'src/Widgets/HyperTextView.vala',
    'src/Widgets/LoadingButton.vala',
    'src/Widgets/ProjectButton.vala',
    'src/Widgets/IconColorProject.vala',
    'src/Widgets/ItemSummary.vala',
    'src/Widgets/ScheduleButton.vala',

    'src/Widgets/Calendar/Calendar.vala',
    'src/Widgets/Calendar/CalendarDay.vala',
    'src/Widgets/Calendar/CalendarHeader.vala',
    'src/Widgets/Calendar/CalendarView.vala',
    'src/Widgets/Calendar/CalendarWeek.vala',

    'src/Views/Welcome.vala',
    'src/Views/Project.vala',
    'src/Views/List.vala',

    'src/Dialogs/TodoistOAuth.vala',
    'src/Dialogs/ProjectPicker/ProjectPicker.vala',
    'src/Dialogs/ProjectPicker/ProjectRow.vala',
    'src/Dialogs/ProjectPicker/SectionRow.vala',
    
    'src/Dialogs/DateTimePicker/DateTimePicker.vala',
    
    'src/Dialogs/ContextMenu/Menu.vala',
    'src/Dialogs/ContextMenu/MenuItem.vala',
    'src/Dialogs/ContextMenu/MenuItemSelector.vala',
    'src/Dialogs/ContextMenu/MenuSeparator.vala',
    'src/Dialogs/ContextMenu/MenuCalendarPicker.vala',

    'src/Services/EventBus.vala',
    'src/Services/Database.vala',
    'src/Services/Todoist.vala',

    'src/Objects/BaseObject.vala',
    'src/Objects/Project.vala',
    'src/Objects/Label.vala',
    'src/Objects/Section.vala',
    'src/Objects/Item.vala',
    'src/Objects/Color.vala',
    'src/Objects/DueDate.vala',
    
    asresources,
    config_header,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gee-0.8', version: '>=0.8.5'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('sqlite3'),
        dependency('json-glib-1.0'),
        dependency('webkit2gtk-4.0'),
        dependency('libhandy-1', version: '>= 0.90.0'),
        meson.get_compiler ('c').find_library ('m', required : false)
    ],
    install: true
)

subdir('data')
# subdir('po')
meson.add_install_script('build-aux/meson/post_install.py')