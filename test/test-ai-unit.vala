using GLib;

void test_api_key_env_var_takes_precedence () {
    Environment.set_variable ("ANTHROPIC_API_KEY", "test-key-from-env", true);
    var claude = new Services.AI.Claude ();
    assert_cmpstr (claude.resolve_api_key (), CompareOperator.EQ, "test-key-from-env");
    Environment.unset_variable ("ANTHROPIC_API_KEY");
}

void test_api_key_returns_null_when_env_not_set_and_no_keyring () {
    // Unset env var. In a CI/test environment with no keyring configured,
    // resolve_api_key() must return null (no stored key).
    // We can only assert this if ANTHROPIC_API_KEY is unset AND there's no
    // keyring entry. If keyring has a stored value, skip the null assertion.
    Environment.unset_variable ("ANTHROPIC_API_KEY");
    var claude = new Services.AI.Claude ();
    string? key = claude.resolve_api_key ();
    // If key is non-null, it came from keyring — that's also valid.
    // We just verify it doesn't crash and returns a usable value or null.
    if (key != null) {
        assert (key.length > 0); // if returned, must be non-empty
    }
    // Verify is_configured() is consistent with resolve_api_key()
    assert_cmpint ((int) claude.is_configured (), CompareOperator.EQ, (int) (key != null));
}

void test_status_starts_not_configured_when_no_key () {
    Environment.unset_variable ("ANTHROPIC_API_KEY");
    var claude = new Services.AI.Claude ();
    // Status should match whether a key is available
    string? key = claude.resolve_api_key ();
    if (key == null) {
        assert (claude.status == Services.AI.Claude.Status.NOT_CONFIGURED);
    } else {
        assert (claude.status == Services.AI.Claude.Status.CONFIGURED);
    }
}

void test_env_var_key_makes_is_configured_true () {
    Environment.set_variable ("ANTHROPIC_API_KEY", "any-test-key", true);
    var claude = new Services.AI.Claude ();
    assert (claude.is_configured ());
    assert (claude.resolve_api_key () != null);
    Environment.unset_variable ("ANTHROPIC_API_KEY");
}

void test_parse_nl_prompt_contains_json_instruction () {
    string prompt = Services.AI.Prompts.parse_natural_language ("buy milk tomorrow");
    assert (prompt.contains ("JSON"));
    assert (prompt.contains ("buy milk tomorrow"));
    assert (prompt.contains ("due_date"));
    assert (prompt.contains ("priority"));
}

void test_generate_subtasks_prompt_contains_task () {
    string prompt = Services.AI.Prompts.generate_subtasks ("Launch website", "");
    assert (prompt.contains ("Launch website"));
    assert (prompt.contains ("JSON"));
}

void test_schedule_items_prompt_contains_today_date () {
    string today = new GLib.DateTime.now_local ().format ("%Y-%m-%d");
    string prompt = Services.AI.Prompts.schedule_items ("[{\"id\":\"1\",\"title\":\"test\"}]");
    assert (prompt.contains (today));
    assert (prompt.contains ("suggested_due_date"));
}

void test_map_import_file_prompt_includes_mime_hint () {
    string prompt = Services.AI.Prompts.map_import_file ("# My Tasks\n- [ ] Do thing", "md");
    assert (prompt.contains ("md"));
    assert (prompt.contains ("# My Tasks"));
    assert (prompt.contains ("projects"));
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/ai/api-key-env-var-precedence", test_api_key_env_var_takes_precedence);
    Test.add_func ("/ai/api-key-null-consistency", test_api_key_returns_null_when_env_not_set_and_no_keyring);
    Test.add_func ("/ai/status-reflects-key-availability", test_status_starts_not_configured_when_no_key);
    Test.add_func ("/ai/env-key-makes-configured", test_env_var_key_makes_is_configured_true);
    Test.add_func ("/ai/prompts/parse-nl", test_parse_nl_prompt_contains_json_instruction);
    Test.add_func ("/ai/prompts/subtasks", test_generate_subtasks_prompt_contains_task);
    Test.add_func ("/ai/prompts/schedule", test_schedule_items_prompt_contains_today_date);
    Test.add_func ("/ai/prompts/import", test_map_import_file_prompt_includes_mime_hint);
    return Test.run ();
}
