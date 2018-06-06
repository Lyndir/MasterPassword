# Native CLI

The CLI is a command-line terminal interface to the Master Password standard implementation.

To use the app, you'll first need to build it, then install it into your system's PATH.

Start by changing into the CLI application directory:

    cd cli


## Building

To build the code to run on your specific system, run the `build` command:

    ./build

Note that the build depends on your system having certain dependencies already installed.
By default, you'll need to have at least `libsodium`, `libjson-c` and `libncurses` installed.


## Building with docker

To install mpw into a Docker container, make sure you have Docker installed on your system, then run something like:

    docker build -f cli/Dockerfile .


## Building with cmake

There is also a cmake configuration you can use to build instead of using the `./build` script.  While `./build` depends on Bash and is geared toward POSIX systems, cmake is platform-independent.  You should use your platform's cmake tools to continue.  On POSIX systems, you can do this:

    cmake . && make

To get a list of options supported by the cmake configuration, use:

    cmake -LH

Options can be toggled like so:

    cmake -DUSE_COLOR=OFF -DBUILD_MPW_TESTS=ON . && make


## Details

The build script comes with a default configuration which can be adjusted.  Full details on the build script are available by opening the build script file.

    [targets='...'] [mpw_feature=0|1 ...] [CFLAGS='...'] [LDFLAGS='...'] ./build [cc arguments ...]

By default, the build script only builds the `mpw` target.  You can specify other targets or `all` to build all available targets.  These are the currently available targets:

 - `mpw`        : The main app.  It needs: `mpw_sodium`, optionally supports: `mpw_color`, `mpw_json`.
 - `mpw-bench`  : A benchmark utility.  It needs: `mpw_sodium`.
 - `mpw-tests`  : An algorithm test suite.  It needs: `mpw_sodium`, `mpw_xml`.

It is smart to build the test suite along with the app, eg.:

    targets='mpw mpw-tests' ./build

The needed and supported features determine the dependencies that the build will require.  The following features exist:

 - `mpw_sodium` : Use Sodium for the crypto implementation.  It needs libsodium.
 - `mpw_json`   : Support JSON-based user configuration format.  It needs libjson-c.
 - `mpw_color`  : Show a colorized identicon.  It needs libncurses.
 - `mpw_xml`    : Support XML parsing.  It needs libxml2.

By default, all features are enabled.  Each feature can be disabled or enabled explicitly by prefixing the build command with an assignment of it to `0` or `1`, eg.:

    mpw_color=0 ./build

As a result of this command, you'd build the `mpw` target (which supports `mpw_color`) without color support.  The build no longer requires `libncurses` but the resulting `mpw` binary will not have support for colorized identicons.

You can also pass CFLAGS or LDFLAGS to the build, or extra custom compiler arguments as arguments to the build script.
For instance, to add a custom library search path, you could use:

    LDFLAGS='-L/usr/local/lib' ./build


## Testing

Once the client is built, you should run a test suite to make sure everything works as intended.

There are currently two test suites:

 - `mpw-tests`     : Tests the Master Password algorithm implementation.
 - `mpw-cli-tests` : Tests the CLI application.

The `mpw-tests` suite is only available if you enabled its target during build (see "Details" above).

The `mpw-cli-tests` is a Bash shell script, hence depends on your system having Bash available.


## Installing

Once you're happy with the result, you can install the `mpw` application into your system's `PATH`.

Generally, all you need to do is copy the `mpw` file into a PATH directory, eg.:

    cp mpw /usr/local/bin/

The directory that you should copy the `mpw` file into will depend on your system.  Also note that `cp` is a POSIX command, if your system is not a POSIX system (eg. Windows) you'll need to adjust accordingly.

There is also an `install` script to help with this process, though it is a Bash script and therefore requires that you have Bash installed:

    ./install

After installing, you should be able to run `mpw` and use it from anywhere in the terminal:

    mpw -h
    mpw google.com
