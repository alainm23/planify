public abstract class Services.CalDAV.Providers.Base {

    public abstract bool is_vtodo_calendar (GXml.DomElement element);

    public static string TASKS_REQUEST = """
        <x1:calendar-query xmlns:x1="urn:ietf:params:xml:ns:caldav">
            <x0:prop xmlns:x0="DAV:">
                <x0:getetag/>
                <x0:displayname/>
                <x0:owner/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
                <x0:getcontenttype/>
                <x0:resourcetype/>
                <x1:calendar-data/>
            </x0:prop>
            <x1:filter>
                <x1:comp-filter name="VCALENDAR">
                    <x1:comp-filter name="VTODO">
                    </x1:comp-filter>
                </x1:comp-filter>
            </x1:filter>
        </x1:calendar-query>
    """;


    public static string TASKLIST_REQUEST = """
        <d:propfind xmlns:d="DAV:" xmlns:ical="http://apple.com/ns/ical/" xmlns:cal="urn:ietf:params:xml:ns:caldav">
            <d:prop>
                <d:resourcetype />
                <d:displayname />
                <d:sync-token />
                <ical:calendar-color />
                <cal:supported-calendar-component-set />
            </d:prop>
        </d:propfind>
    """;
}
