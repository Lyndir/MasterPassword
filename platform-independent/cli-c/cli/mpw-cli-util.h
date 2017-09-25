//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "mpw-types.h"

#ifndef MP_VERSION
#define MP_VERSION ?
#endif

#define MP_ENV_fullName     "MPW_FULLNAME"
#define MP_ENV_algorithm    "MPW_ALGORITHM"
#define MP_ENV_format       "MPW_FORMAT"
#define MP_ENV_askpass      "MPW_ASKPASS"

/** Read the value of an environment variable.
  * @return A newly allocated string or NULL if the variable doesn't exist. */
const char *mpw_getenv(const char *variableName);

/** Use the askpass program to prompt the user.
  * @return A newly allocated string or NULL if askpass is not supported or an error occurred. */
char *mpw_askpass(const char *prompt);

/** Ask the user a question.
  * @return A newly allocated string or NULL if an error occurred trying to read from the user. */
const char *mpw_getline(const char *prompt);

/** Ask the user for a password.
  * @return A newly allocated string or NULL if an error occurred trying to read from the user. */
const char *mpw_getpass(const char *prompt);

/** Get the absolute path to the mpw configuration file with the given prefix name and file extension.
  * Resolves the file <prefix.extension> as located in the <.mpw.d> directory inside the user's home directory
  * or current directory if it couldn't be resolved.
  * @return A newly allocated string. */
const char *mpw_path(const char *prefix, const char *extension);

/** mkdir all the directories up to the directory of the given file path.
  * @return true if the file's path exists. */
bool mpw_mkdirs(const char *filePath);

/** Read until EOF from the given file descriptor.
  * @return A newly allocated string or NULL the read buffer couldn't be allocated. */
char *mpw_read_fd(int fd);

/** Read the file contents of a given file.
  * @return A newly allocated string or NULL the read buffer couldn't be allocated. */
char *mpw_read_file(FILE *file);

/** Encode a visual fingerprint for a user.
  * @return A newly allocated string. */
const char *mpw_identicon_str(MPIdenticon identicon);
