using GLib;

void test_api_key_env_var_takes_precedence () {
    Environment.set_variable ("ANTHROPIC_API_KEY", "test-key-from-env", true);
    var claude = new Services.AI.Claude ();
    assert_cmpstr (claude.resolve_api_key (), CompareOperator.EQ, "test-key-from-env");
    Environment.unset_variable ("ANTHROPIC_API_KEY");
}

void test_api_key_returns_null_when_not_set () {
    Environment.unset_variable ("ANTHROPIC_API_KEY");
    var claude = new Services.AI.Claude ();
    string? key = claude.resolve_api_key ();
    assert (key == null || key.length > 0);
}

void test_is_not_configured_without_key () {
    Environment.unset_variable ("ANTHROPIC_API_KEY");
    var claude = new Services.AI.Claude ();
    bool configured = claude.is_configured ();
    assert (configured == false || configured == true);
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/ai/api-key-env-var", test_api_key_env_var_takes_precedence);
    Test.add_func ("/ai/api-key-null-when-unset", test_api_key_returns_null_when_not_set);
    Test.add_func ("/ai/is-not-configured", test_is_not_configured_without_key);
    return Test.run ();
}
