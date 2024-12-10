/*
 * Copyright (C) 2024 Vladimir Vaskov
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 * 
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Apa {
    public async int search (
        owned ArgsHandler args_handler,
        bool skip_unknown_options = false
    ) throws CommandError, OptionsError {
        var error = new Gee.ArrayList<string> ();

        args_handler.init_options (
            OptionData.concat (Cache.Data.COMMON_OPTIONS_DATA, Cache.Data.SEARCH_OPTIONS_DATA),
            OptionData.concat (Cache.Data.COMMON_ARG_OPTIONS_DATA, Cache.Data.SEARCH_ARG_OPTIONS_DATA),
            skip_unknown_options
        );

        if (args_handler.args.size == 0) {
            throw new CommandError.NO_PACKAGES (_("Nothing to search"));
        }

        while (true) {
            error.clear ();
            var status = yield Cache.search (args_handler, null, error);

            if (status != ExitCode.SUCCESS && error.size > 0) {
                string error_message = normalize_error (error);
                string? package;

                switch (detect_error (error_message, out package)) {
                    case OriginErrorType.CONFIGURATION_ITEM_SPECIFICATION_MUST_HAVE_AN_VAL:
                        print_error (_("Option `-o/--option' value is incorrect. It should look like OptionName=val"));
                        return status;

                    case OriginErrorType.OPEN_CONFIGURATION_FILE_FAILED:
                        print_error (_("Option `-c/--config' value is incorrect"));
                        return status;

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