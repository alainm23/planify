/*
 * Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

namespace Constants {
    public const string SOUP_USER_AGENT = "Planify";
    public const string TODOIST_CLIENT_ID = "b0dd7d3714314b1dbbdab9ee03b6b432";
    public const string TODOIST_CLIENT_SECRET = "a86dfeb12139459da3e5e2a8c197c678";
    public const string TODOIST_SCOPE = "data:read_write,data:delete,project:delete";
    public const string BACKUP_VERSION = "2.0";
    public const int UPDATE_TIMEOUT = 1500;
    public const int DESTROY_TIMEOUT = 750;
    public const int STARTUP_SYNC_TIMEOUT = 2500;
    public const int SHORT_NAME_SIZE = 20;
    public const int PRIORITY_1 = 4;
    public const int PRIORITY_2 = 3;
    public const int PRIORITY_3 = 2;
    public const int PRIORITY_4 = 1;
    public const int SCROLL_STEPS = 6;
    public const string TWITTER_URL = "https://twitter.com/useplanify";
    public const string CONTACT_US = "alainmh23@gmail.com";
    public const string PATREON_URL = "https://www.patreon.com/join/alainm23";
    public const string PAYPAL_ME_URL = "https://www.paypal.com/paypalme/alainm23";
    public const string LIBERAPAY_URL = "https://liberapay.com/Alain/";
    public const string KOFI_URL = "https://ko-fi.com/alainm23";
    public const string MASTODON_URL = "https://mastodon.social/@planifyapp";
    public const string DISCORD_URL = "https://discord.com/invite/dxxyumrTJW";
    public const string ISSUE_URL = "https://github.com/alainm23/planify/issues";
    public const string WEBLATE_URL = "https://hosted.weblate.org/engage/planner/";
    public const string FLATHUB_URL = "https://flathub.org/apps/io.github.alainm23.planify";
    public const string PRIVACY_POLICY_URL = "https://useplanify.com/privacy-policy/";
    public const bool BLOCK_PAST_DAYS = false;
    public const int COMPLETED_PAGE_SIZE = 15;
    public const int HEADERBAR_TITLE_SCROLL_THRESHOLD = 24;
}
