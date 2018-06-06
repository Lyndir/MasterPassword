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

#define _POSIX_C_SOURCE 200809L

#include "mpw-cli-util.h"

#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <pwd.h>
#include <string.h>
#include <errno.h>
#include <sysexits.h>

#define MPW_MAX_INPUT 60

#if MPW_COLOR
#include <curses.h>
#include <term.h>
#endif

#include "mpw-util.h"

const char *mpw_getenv(const char *variableName) {

    char *envBuf = getenv( variableName );
    return envBuf? mpw_strdup( envBuf ): NULL;
}

char *mpw_askpass(const char *prompt) {

    const char *askpass = mpw_getenv( MP_ENV_askpass );
    if (!askpass)
        return NULL;

    int pipes[2];
    if (pipe( pipes ) == ERR) {
        wrn( "Couldn't pipe: %s", strerror( errno ) );
        return NULL;
    }

    pid_t pid = fork();
    if (pid == ERR) {
        wrn( "Couldn't fork for askpass:\n  %s: %s", askpass, strerror( errno ) );
        return NULL;
    }

    if (!pid) {
        // askpass fork
        close( pipes[0] );
        if (dup2( pipes[1], STDOUT_FILENO ) == ERR)
            ftl( "Couldn't connect pipe to process: %s", strerror( errno ) );

        else if (execlp( askpass, askpass, prompt, NULL ) == ERR)
            ftl( "Couldn't execute askpass:\n  %s: %s", askpass, strerror( errno ) );

        exit( EX_SOFTWARE );
    }

    close( pipes[1] );
    char *answer = mpw_read_fd( pipes[0] );
    close( pipes[0] );
    int status;
    if (waitpid( pid, &status, 0 ) == ERR) {
        wrn( "Couldn't wait for askpass: %s", strerror( errno ) );
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

static const char *_mpw_getline(const char *prompt, bool silent) {

    // Get answer from askpass.
    char *answer = mpw_askpass( prompt );
    if (answer)
        return answer;

#if MPW_COLOR
    // Initialize a curses screen.
    SCREEN *screen = newterm( NULL, stderr, stdin );
    start_color();
    init_pair( 1, COLOR_WHITE, COLOR_BLUE );
    init_pair( 2, COLOR_BLACK, COLOR_WHITE );
    int rows, cols;
    getmaxyx( stdscr, rows, cols );

    // Display a dialog box.
    int width = max( prompt? (int)strlen( prompt ): 0, MPW_MAX_INPUT ) + 6;
    char *version = "mpw v" stringify_def( MP_VERSION );
    mvprintw( rows - 1, (cols - (int)strlen( version )) / 2, "%s", version );
    attron( A_BOLD );
    color_set( 2, NULL );
    mvprintw( rows / 2 - 1, (cols - width) / 2, "%s%*s%s", "*", width - 2, "", "*" );
    mvprintw( rows / 2 - 1, (cols - (int)strlen( prompt )) / 2, "%s", prompt );
    color_set( 1, NULL );
    mvprintw( rows / 2 + 0, (cols - width) / 2, "%s%*s%s", "|", width - 2, "", "|" );
    mvprintw( rows / 2 + 1, (cols - width) / 2, "%s%*s%s", "|", width - 2, "", "|" );
    mvprintw( rows / 2 + 2, (cols - width) / 2, "%s%*s%s", "|", width - 2, "", "|" );

    // Read response.
    color_set( 2, NULL );
    attron( A_STANDOUT );
    int result = ERR;
    char str[MPW_MAX_INPUT + 1];
    if (silent) {
        mvprintw( rows / 2 + 1, (cols - 5) / 2, "[ * ]" );
        refresh();

        noecho();
        result = mvgetnstr( rows / 2 + 1, (cols - 1) / 2, str, MPW_MAX_INPUT );
        echo();
    } else {
        mvprintw( rows / 2 + 1, (cols - (MPW_MAX_INPUT + 2)) / 2, "%*s", MPW_MAX_INPUT + 2, "" );
        refresh();

        echo();
        result = mvgetnstr( rows / 2 + 1, (cols - MPW_MAX_INPUT) / 2, str, MPW_MAX_INPUT );
    }
    attrset( 0 );
    endwin();
    delscreen( screen );

    return result == ERR? NULL: mpw_strndup( str, MPW_MAX_INPUT );
#else
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
#endif
}

const char *mpw_getline(const char *prompt) {

    return _mpw_getline( prompt, false );
}

const char *mpw_getpass(const char *prompt) {

    return _mpw_getline( prompt, true );
}

const char *mpw_path(const char *prefix, const char *extension) {

    // Resolve user's home directory.
    char *homeDir = NULL;
    if (!homeDir)
        if ((homeDir = getenv( "HOME" )))
            homeDir = mpw_strdup( homeDir );
    if (!homeDir)
        if ((homeDir = getenv( "USERPROFILE" )))
            homeDir = mpw_strdup( homeDir );
    if (!homeDir) {
        const char *homeDrive = getenv( "HOMEDRIVE" ), *homePath = getenv( "HOMEPATH" );
        if (homeDrive && homePath)
            homeDir = mpw_strdup( mpw_str( "%s%s", homeDrive, homePath ) );
    }
    if (!homeDir) {
        struct passwd *passwd = getpwuid( getuid() );
        if (passwd)
            homeDir = mpw_strdup( passwd->pw_dir );
    }
    if (!homeDir)
        homeDir = getcwd( NULL, 0 );

    // Compose filename.
    char *path = mpw_strdup( mpw_str( "%s.%s", prefix, extension ) );

    // This is a filename, remove all potential directory separators.
    for (char *slash; (slash = strstr( path, "/" )); *slash = '_');

    // Compose pathname.
    if (homeDir) {
        const char *homePath = mpw_str( "%s/.mpw.d/%s", homeDir, path );
        free( homeDir );
        free( path );

        if (homePath)
            path = mpw_strdup( homePath );
    }

    return path;
}

bool mpw_mkdirs(const char *filePath) {

    if (!filePath)
        return false;

    // Save the cwd and for absolute paths, start at the root.
    char *cwd = getcwd( NULL, 0 );
    if (*filePath == '/')
        if (chdir( "/" ) == ERR)
            return false;

    // The path to mkdir is the filePath without the last path component.
    char *pathEnd = strrchr( filePath, '/' );
    if (!pathEnd)
        return true;

    // Walk the path.
    bool success = true;
    char *path = mpw_strndup( filePath, (size_t)(pathEnd - filePath) );
    for (char *dirName = strtok( path, "/" ); success && dirName; dirName = strtok( NULL, "/" )) {
        if (!strlen( dirName ))
            continue;

        success &= (mkdir( dirName, 0700 ) != ERR || errno == EEXIST) && chdir( dirName ) != ERR;
    }
    free( path );

    if (chdir( cwd ) == ERR)
        wrn( "Could not restore cwd:\n  %s: %s", cwd, strerror( errno ) );
    free( cwd );

    return success;
}

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

#if MPW_COLOR
static char *str_tputs;
static int str_tputs_cursor;
static const int str_tputs_max = 256;

static bool mpw_setupterm() {

    if (!isatty( STDERR_FILENO ))
        return false;

    static bool termsetup;
    if (!termsetup) {
        int errret;
        if (!(termsetup = (setupterm( NULL, STDERR_FILENO, &errret ) == OK))) {
            wrn( "Terminal doesn't support color (setupterm errret %d).", errret );
            return false;
        }
    }

    return true;
}

static int mpw_tputc(int c) {

    if (++str_tputs_cursor < str_tputs_max) {
        str_tputs[str_tputs_cursor] = (char)c;
        return OK;
    }

    return ERR;
}

static char *mpw_tputs(const char *str, int affcnt) {

    if (str_tputs)
        mpw_free( &str_tputs, str_tputs_max );
    str_tputs = calloc( str_tputs_max, sizeof( char ) );
    str_tputs_cursor = -1;

    char *result = tputs( str, affcnt, mpw_tputc ) == ERR? NULL: mpw_strndup( str_tputs, str_tputs_max );
    if (str_tputs)
        mpw_free( &str_tputs, str_tputs_max );

    return result;
}

#endif

const char *mpw_identicon_str(MPIdenticon identicon) {

    char *colorString, *resetString;
#ifdef MPW_COLOR
    if (mpw_setupterm()) {
        colorString = mpw_tputs( tparm( tgetstr( "AF", NULL ), identicon.color ), 1 );
        resetString = mpw_tputs( tgetstr( "me", NULL ), 1 );
    }
    else
#endif
    {
        colorString = calloc( 1, sizeof( char ) );
        resetString = calloc( 1, sizeof( char ) );
    }

    const char *str = mpw_str( "%s%s%s%s%s%s",
            colorString, identicon.leftArm, identicon.body, identicon.rightArm, identicon.accessory, resetString );
    mpw_free_strings( &colorString, &resetString, NULL );

    return mpw_strdup( str );
}
