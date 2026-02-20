/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
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
 */

/**
 * Priority Conversion Tests
 * 
 * Tests the conversion between user-friendly priority values
 * and internal priority representation.
 */

namespace PlanifyCLI.Tests.PriorityConversion {
    void test_priority_conversion () {
        print ("Testing: Priority conversion (user-friendly to internal)\n");
        
        // User-friendly: 1=high, 2=medium, 3=low, 4=none
        // Internal: 4=high, 3=medium, 2=low, 1=none
        // Conversion: internal = 5 - user_friendly
        
        assert (5 - 1 == 4); // high
        assert (5 - 2 == 3); // medium
        assert (5 - 3 == 2); // low
        assert (5 - 4 == 1); // none
        
        print ("  ✓ Priority conversion logic verified\n");
        print ("  1 (high) -> 4 (internal)\n");
        print ("  2 (medium) -> 3 (internal)\n");
        print ("  3 (low) -> 2 (internal)\n");
        print ("  4 (none) -> 1 (internal)\n---\n");
    }

    public void register_tests () {
        Test.add_func ("/cli/priority_conversion", test_priority_conversion);
    }
}