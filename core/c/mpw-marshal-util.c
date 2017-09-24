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

#include <string.h>

#include "mpw-marshal-util.h"
#include "mpw-util.h"

char *mpw_get_token(const char **in, const char *eol, char *delim) {

    // Skip leading spaces.
    for (; **in == ' '; ++*in);

    // Find characters up to the first delim.
    size_t len = strcspn( *in, delim );
    char *token = len && len <= (size_t)(eol - *in)? strndup( *in, len ): NULL;

    // Advance past the delimitor.
    *in = min( eol, *in + len + 1 );
    return token;
}

time_t mpw_mktime(
        const char *time) {

    struct tm tm = { .tm_isdst = -1, .tm_gmtoff = 0 };
    if (time && sscanf( time, "%4d-%2d-%2dT%2d:%2d:%2dZ",
            &tm.tm_year, &tm.tm_mon, &tm.tm_mday,
            &tm.tm_hour, &tm.tm_min, &tm.tm_sec ) == 6) {
        tm.tm_year -= 1900; // tm_year 0 = rfc3339 year  1900
        tm.tm_mon -= 1;     // tm_mon  0 = rfc3339 month 1
        /*
* thread #1, queue = 'com.apple.main-thread', stop reason = EXC_ARITHMETIC (code=EXC_I386_DIV, subcode=0x0)
    frame #0: 0x00007fff9fe4d219 libsystem_notify.dylib`_nc_table_find_64 + 22
libsystem_notify.dylib`_nc_table_find_64:
->  0x7fff9fe4d219 <+22>: divl   0x4(%rdi)
    0x7fff9fe4d21c <+25>: movq   0x8(%rdi), %rax
    0x7fff9fe4d220 <+29>: movq   (%rax,%rdx,8), %rcx
    0x7fff9fe4d224 <+33>: xorl   %eax, %eax
(lldb) bt
* thread #1, queue = 'com.apple.main-thread', stop reason = EXC_ARITHMETIC (code=EXC_I386_DIV, subcode=0x0)
  * frame #0: 0x00007fff9fe4d219 libsystem_notify.dylib`_nc_table_find_64 + 22
    frame #1: 0x00007fff9fe4a21e libsystem_notify.dylib`registration_node_find + 53
    frame #2: 0x00007fff9fe4b78d libsystem_notify.dylib`notify_check + 105
    frame #3: 0x00007fff9fccc164 libsystem_c.dylib`notify_check_tz + 24
    frame #4: 0x00007fff9fccbd97 libsystem_c.dylib`tzsetwall_basic + 45
    frame #5: 0x00007fff9fccdcd0 libsystem_c.dylib`mktime + 46
    frame #6: 0x0000000100009496 mpw`mpw_mktime(time="2017-04-16T03:16:35Z") at mpw-marshal-util.c:47
         */
        return mktime( &tm );
    }

    return false;
}

#if MPW_JSON
json_object *mpw_get_json_section(
        json_object *obj, const char *section) {

    json_object *json_value = obj;
    char *sectionTokenizer = strdup( section ), *sectionToken = sectionTokenizer;
    for (sectionToken = strtok( sectionToken, "." ); sectionToken; sectionToken = strtok( NULL, "." ))
        if (!json_object_object_get_ex( json_value, sectionToken, &json_value ) || !json_value) {
            trc( "While resolving: %s: Missing value for: %s\n", section, sectionToken );
            json_value = NULL;
            break;
        }
    free( sectionTokenizer );

    return json_value;
}

const char *mpw_get_json_string(
        json_object *obj, const char *section, const char *defaultValue) {

    json_object *json_value = mpw_get_json_section( obj, section );
    if (!json_value)
        return defaultValue;

    return json_object_get_string( json_value );
}

int64_t mpw_get_json_int(
        json_object *obj, const char *section, int64_t defaultValue) {

    json_object *json_value = mpw_get_json_section( obj, section );
    if (!json_value)
        return defaultValue;

    return json_object_get_int64( json_value );
}

bool mpw_get_json_boolean(
        json_object *obj, const char *section, bool defaultValue) {

    json_object *json_value = mpw_get_json_section( obj, section );
    if (!json_value)
        return defaultValue;

    return json_object_get_boolean( json_value ) == TRUE;
}
#endif

bool mpw_update_masterKey(MPMasterKey *masterKey, MPAlgorithmVersion *masterKeyAlgorithm, MPAlgorithmVersion targetKeyAlgorithm,
        const char *fullName, const char *masterPassword) {

    if (*masterKeyAlgorithm != targetKeyAlgorithm) {
        mpw_free( masterKey, MPMasterKeySize );
        *masterKeyAlgorithm = targetKeyAlgorithm;
        *masterKey = mpw_masterKey( fullName, masterPassword, *masterKeyAlgorithm );
        if (!*masterKey) {
            err( "Couldn't derive master key for user %s, algorithm %d.\n", fullName, *masterKeyAlgorithm );
            return false;
        }
    }

    return true;
}
