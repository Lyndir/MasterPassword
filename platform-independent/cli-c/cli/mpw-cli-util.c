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

#include "mpw-cli-util.h"

#include <unistd.h>
#include <sys/stat.h>
#include <pwd.h>
#include <string.h>
#include <errno.h>
#include <sysexits.h>

#include "mpw-util.h"

/** Read the value of an environment variable.
  * @return A newly allocated string or NULL if the variable doesn't exist. */
const char *mpw_getenv(const char *variableName) {

    char *envBuf = getenv( variableName );
    return envBuf? strdup( envBuf ): NULL;
}

/** Use the askpass program to prompt the user.
  * @return A newly allocated string or NULL if askpass is not supported or an error occurred. */
char *mpw_askpass(const char *prompt) {

    const char *askpass = mpw_getenv( MP_ENV_askpass );
    if (!askpass)
        return NULL;

    int pipes[2];
    if (pipe( pipes ) == ERR) {
        wrn( "Couldn't pipe: %s\n", strerror( errno ) );
        return NULL;
    }

    pid_t pid = fork();
    if (pid == ERR) {
        wrn( "Couldn't fork for askpass:\n  %s: %s\n", askpass, strerror( errno ) );
        return NULL;
    }

    if (!pid) {
        // askpass fork
        close( pipes[0] );
        if (dup2( pipes[1], STDOUT_FILENO ) == ERR)
            ftl( "Couldn't connect pipe to process: %s\n", strerror( errno ) );

        else if (execlp( askpass, askpass, prompt, NULL ) == ERR)
            ftl( "Couldn't execute askpass:\n  %s: %s\n", askpass, strerror( errno ) );

        exit( EX_SOFTWARE );
    }

    close( pipes[1] );
    char *answer = mpw_read_fd( pipes[0] );
    close( pipes[0] );
    int status;
    if (waitpid( pid, &status, 0 ) == ERR) {
        wrn( "Couldn't wait for askpass: %s\n", strerror( errno ) );
        mpw_free_string( &answer );
        return NULL;
    }

    if (WIFEXITED( status ) && WEXITSTATUS( status ) == EXIT_SUCCESS && answer && strlen( answer )) {
        // Remove trailing newline.
        if (answer[strlen( answer ) - 1] == '\n')
            answer[strlen( answer ) - 1] = '\0';
        return answer;
    }

    mpw_free_string( &answer );
    return NULL;
}

/** Ask the user a question.
  * @return A newly allocated string or NULL if an error occurred trying to read from the user. */
const char *mpw_getline(const char *prompt) {

    // Get answer from askpass.
    char *answer = mpw_askpass( prompt );
    if (answer)
        return answer;

    // Get password from terminal.
    fprintf( stderr, "%s ", prompt );

    size_t bufSize = 0;
    ssize_t lineSize = getline( &answer, &bufSize, stdin );
    if (lineSize <= 1) {
        mpw_free_string( &answer );
        return NULL;
    }

    // Remove trailing newline.
    answer[lineSize - 1] = '\0';
    return answer;
}

/** Ask the user for a password.
  * @return A newly allocated string or NULL if an error occurred trying to read from the user. */
const char *mpw_getpass(const char *prompt) {

    // Get password from askpass.
    const char *password = mpw_askpass( prompt );
    if (password)
        return password;

    // Get password from terminal.
    char *answer = getpass( prompt );
    if (!answer)
        return NULL;

    password = strdup( answer );
    bzero( answer, strlen( answer ) );
    return password;
}

/** Get the absolute path to the mpw configuration file with the given prefix name and file extension.
  * Resolves the file <prefix.extension> as located in the <.mpw.d> directory inside the user's home directory
  * or current directory if it couldn't be resolved.
  * @return A newly allocated string. */
const char *mpw_path(const char *prefix, const char *extension) {

    // Resolve user's home directory.
    char *homeDir = NULL;
    if (!homeDir)
        if ((homeDir = getenv( "HOME" )))
            homeDir = strdup( homeDir );
    if (!homeDir)
        if ((homeDir = getenv( "USERPROFILE" )))
            homeDir = strdup( homeDir );
    if (!homeDir) {
        const char *homeDrive = getenv( "HOMEDRIVE" ), *homePath = getenv( "HOMEPATH" );
        if (homeDrive && homePath)
            homeDir = strdup( mpw_str( "%s%s", homeDrive, homePath ) );
    }
    if (!homeDir) {
        struct passwd *passwd = getpwuid( getuid() );
        if (passwd)
            homeDir = strdup( passwd->pw_dir );
    }
    if (!homeDir)
        homeDir = getcwd( NULL, 0 );

    // Compose filename.
    char *path = strdup( mpw_str( "%s.%s", prefix, extension ) );

    // This is a filename, remove all potential directory separators.
    for (char *slash; (slash = strstr( path, "/" )); *slash = '_');

    // Compose pathname.
    if (homeDir) {
        const char *homePath = mpw_str( "%s/.mpw.d/%s", homeDir, path );
        free( homeDir );
        free( path );

        if (homePath)
            path = strdup( homePath );
    }

    return path;
}

/** mkdir all the directories up to the directory of the given file path.
  * @return true if the file's path exists. */
bool mpw_mkdirs(const char *filePath) {

    if (!filePath)
        return false;

    // The path to mkdir is the filePath without the last path component.
    char *pathEnd = strrchr( filePath, '/' );
    char *path = pathEnd? strndup( filePath, (size_t)(pathEnd - filePath) ): NULL;
    if (!path)
        return false;

    // Save the cwd and for absolute paths, start at the root.
    char *cwd = getcwd( NULL, 0 );
    if (*filePath == '/')
        chdir( "/" );

    // Walk the path.
    bool success = true;
    for (char *dirName = strtok( path, "/" ); success && dirName; dirName = strtok( NULL, "/" )) {
        if (!strlen( dirName ))
            continue;

        success &= (mkdir( dirName, 0700 ) != ERR || errno == EEXIST) && chdir( dirName ) != ERR;
    }
    free( path );

    if (chdir( cwd ) == ERR)
        wrn( "Could not restore cwd:\n  %s: %s\n", cwd, strerror( errno ) );
    free( cwd );

    return success;
}

/** Read until EOF from the given file descriptor.
  * @return A newly allocated string or NULL if the read buffer couldn't be allocated or an error occurred. */
char *mpw_read_fd(int fd) {

    char *buf = NULL;
    size_t blockSize = 4096, bufSize = 0, bufOffset = 0;
    ssize_t readSize = 0;
    while ((mpw_realloc( &buf, &bufSize, blockSize )) &&
           ((readSize = read( fd, buf + bufOffset, blockSize )) > 0));
    if (readSize == ERR)
        mpw_free( &buf, bufSize );

    return buf;
}

/** Read the file contents of a given file.
  * @return A newly allocated string or NULL if the read buffer couldn't be allocated. */
char *mpw_read_file(FILE *file) {

    if (!file)
        return NULL;

    char *buf = NULL;
    size_t blockSize = 4096, bufSize = 0, bufOffset = 0, readSize = 0;
    while ((mpw_realloc( &buf, &bufSize, blockSize )) &&
           (bufOffset += (readSize = fread( buf + bufOffset, 1, blockSize, file ))) &&
           (readSize == blockSize));

    return buf;
}
