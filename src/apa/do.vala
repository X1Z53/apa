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
    internal async int @do (owned CommandArgs ca) throws CommandError {
        foreach (var package_name in ca.command_argv) {
            if (!package_name.has_suffix ("-") && !package_name.has_suffix ("+")) {
                print_error (_("Unknown operation '%c' in %s").printf (
                    package_name[package_name.length - 1],
                    package_name
                ));
                return Constants.ExitCode.BASE_ERROR;
            }
        }

        while (true) {
            var error = new Gee.ArrayList<string> ();
            var status = yield Get.do (ca.command_argv, ca.options, ca.arg_options, error);

            if (status != Constants.ExitCode.SUCCESS && error.size > 0) {
                string error_message = normalize_error (error);
                string? package_error_source;

                switch (detect_error (error_message, out package_error_source)) {
                    case OriginErrorType.COULDNT_FIND_PACKAGE:
                        string package_error_source_name = package_error_source[0:package_error_source.length - 1];
                        char package_error_source_operation = package_error_source[package_error_source.length - 1];

                        string[]? possible_package_names;

                        var package_name_straight = package_error_source_name.replace ("-", "");
                        switch (package_error_source_operation) {
                            case '+':
                                var search_result = new Gee.ArrayList<string> ();
                                yield Cache.search (
                                    { string.joinv (".*", split_chars (package_name_straight)) },
                                    { "--names-only" },
                                    ca.arg_options,
                                    search_result,
                                    null,
                                    true
                                );
                                do_short_array_list (ref search_result);

                                possible_package_names = fuzzy_search (package_name_straight, search_result.to_array ());
                                break;

                            case '-':
                                var installed_result = new Gee.ArrayList<string> ();
                                yield Rpm.list ({ "-s" }, {}, installed_result);

                                possible_package_names = fuzzy_search (package_name_straight, installed_result.to_array ());
                                break;

                            default:
                                assert_not_reached ();
                        }

                        print (_("Package %s not found, but packages with a similar name were found:").printf (package_error_source));
                        string? answer;
                        var result = give_choice (possible_package_names, _("remove"), out answer);

                        switch (result) {
                            case ChoiceResult.SKIP:
                                remove_element_from_array (ref ca.command_argv, package_error_source);
                                if (ca.command_argv.length == 0) {
                                    print (_("There are no packages left to do"));
                                    return 0;
                                }
                                break;

                            case ChoiceResult.CHOSEN:
                                replace_strings_in_array (
                                    ref ca.command_argv,
                                    package_error_source,
                                    answer.split (" ")[0] + package_error_source_operation.to_string ()
                                );
                                break;

                            case ChoiceResult.EXIT:
                                return status;
                        }
                        break;

                    case OriginErrorType.PACKAGE_VIRTUAL_WITH_MULTIPLE_GOOD_PROIDERS:
                        char package_error_source_operation = package_error_source[package_error_source.length - 1];

                        print (error_message[0:error_message.length - 1] + ":");

                        var packages = new Gee.ArrayList<string> ();
                        foreach (var err in error) {
                            if (err.has_prefix ("  ")) {
                                string[] strs = err.strip ().split (" ");
                                if (strs[strs.length - 1].has_suffix ("]") && strs[strs.length - 1].has_prefix ("[")) {
                                    packages.add ("%s (%s)".printf (
                                        strs[0],
                                        strs[strs.length - 1][1: strs[strs.length - 1].length - 1]
                                    ));

                                } else {
                                    packages.add (strs[0]);
                                }
                            }
                        }

                        string? answer;
                        var result = give_choice (packages.to_array (), _("install"), out answer);

                        switch (result) {
                            case ChoiceResult.SKIP:
                                remove_element_from_array (ref ca.command_argv, package_error_source);
                                if (ca.command_argv.length == 0) {
                                    print (_("There are no packages left to install"));
                                    return 0;
                                }
                                break;

                            case ChoiceResult.CHOSEN:
                                replace_strings_in_array (
                                    ref ca.command_argv,
                                    package_error_source,
                                    answer.split (" ")[0] + package_error_source_operation.to_string ()
                                );
                                break;

                            case ChoiceResult.EXIT:
                                return status;
                        }
                        break;

                    case OriginErrorType.UNABLE_TO_LOCK_DOWNLOAD_DIR:
                        print_error (_("APT is currently busy"));
                        return status;

                    case OriginErrorType.NONE:
                    default:
                        print_error (_("Unknown error message: '%s'").printf (error_message));
                        print_issue ();
                        return Constants.ExitCode.BASE_ERROR;
                }

            } else {
                return status;
            }
        }
    }
}