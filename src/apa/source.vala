/*
 * Copyright 2024 Vladimir Vaskov
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Apa {
    public async int source (
        owned ArgvHandler command_handler,
        bool ignore_unknown_options = false
    ) throws CommandError {
        var error = new Gee.ArrayList<string> ();

        while (true) {
            error.clear ();
            var status = yield Get.source (command_handler, error, ignore_unknown_options);

            if (status != Constants.ExitCode.SUCCESS && error.size > 0) {
                string error_message = normalize_error (error);
                string? package_error_source;

                switch (detect_error (error_message, out package_error_source)) {
                    case OriginErrorType.NONE:
                    default:
                        throw new CommandError.UNKNOWN_ERROR (error_message);
                }

            } else {
                return status;
            }
        }
    }
}
