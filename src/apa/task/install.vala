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

namespace Apa.Task {
    public async int install (
        owned ArgsHandler args_handler,
        bool skip_unknown_options = false
    ) throws CommandError, OptionsError {
        var error = new Gee.ArrayList<string> ();

        args_handler.init_options (
            OptionData.concat (AptRepo.Data.COMMON_OPTIONS_DATA, AptRepo.Data.TEST_OPTIONS_DATA),
            OptionData.concat (AptRepo.Data.COMMON_ARG_OPTIONS_DATA, AptRepo.Data.TEST_ARG_OPTIONS_DATA),
            skip_unknown_options
        );

        if (args_handler.args.size == 0) {
            throw new CommandError.NO_PACKAGES (_("Nothing to install"));
        }

        if (args_handler.args.size > 1) {
            throw new CommandError.COMMON (_("Too many arguments"));
        }

        while (true) {
            error.clear ();
            var status = yield AptRepo.test (args_handler, error, skip_unknown_options);

            if (status != ExitCode.SUCCESS && error.size > 0) {
                string error_message = normalize_error (error);
                string? task;

                switch (detect_error (error_message, out task)) {
                    case OriginErrorType.UNABLE_TO_LOCK_DOWNLOAD_DIR:
                        print_error (_("APT is currently busy"));
                        return status;

                    case OriginErrorType.TASK_IS_UNKNOWN_OR_STILL_BUILDING:
                        throw new CommandError.TASK_IS_UNKNOWN (task);

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
