public class Chrono.en : GLib.Object {
    // now, today, tomorrow, tmr
    private GLib.Regex PARSING_CONTEXT_EN = /(now|today|tomorrow|tmr|yesterday)(?=\W|$)/;

    // jan, january, feb, february, etc
    private GLib.Regex MONTHS = /(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)/;
    private GLib.Regex DAYS = /\d{1,2}(th)?/;

    private GLib.Regex
}