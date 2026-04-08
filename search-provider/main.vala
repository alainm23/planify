int main (string[] args) {
    Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.GNOMELOCALEDIR);
    Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Build.GETTEXT_PACKAGE);

    var app = new Planify.SearchProvider ();
    return app.run (args);
}
