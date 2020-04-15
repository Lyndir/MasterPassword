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

package com.lyndir.masterpassword.impl;

import com.google.common.base.Joiner;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableSet;
import com.google.common.io.ByteStreams;
import com.lyndir.lhunath.opal.system.logging.Logger;
import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;
import java.io.*;
import java.util.*;
import java.util.function.Predicate;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-05-22
 */
public final class Native {

    private static final Logger logger = Logger.get( Native.class );

    @SuppressWarnings("HardcodedFileSeparator")
    private static final char   RESOURCE_SEPARATOR  = '/';
    private static final char   EXTENSION_SEPARATOR = '.';
    private static final String NATIVES_PATH        = "lib";

    @SuppressFBWarnings({"PATH_TRAVERSAL_IN", "IOI_USE_OF_FILE_STREAM_CONSTRUCTORS", "EXS_EXCEPTION_SOFTENING_RETURN_FALSE"})
    @SuppressWarnings({ "HardcodedFileSeparator", "LoadLibraryWithNonConstantString" })
    public static boolean load(final Class<?> context, final String name) {

        // Try to load the library using the native system.
        try {
            System.loadLibrary( name );
            return true;
        }
        catch (@SuppressWarnings("ErrorNotRethrown") final UnsatisfiedLinkError ignored) {
        }

        // Try to find and open a stream to the packaged library resource.
        String             library          = System.mapLibraryName( name );
        int                libraryDot       = library.lastIndexOf( EXTENSION_SEPARATOR );
        String             libraryName      = (libraryDot > 0)? library.substring( 0, libraryDot ): library;
        String             libraryExtension = (libraryDot > 0)? library.substring( libraryDot ): ".lib";

        @Nullable
        File libraryFile = null;
        Set<String> libraryResources = getLibraryResources( library );
        for (final String libraryResource : libraryResources) {
            try {
                InputStream libraryStream = context.getResourceAsStream( libraryResource );
                if (libraryStream == null) {
                    logger.dbg( "No resource for library: %s", libraryResource );
                    continue;
                }

                // Write the library resource to a temporary file.
                libraryFile = File.createTempFile( libraryName, libraryExtension );
                libraryFile.deleteOnExit();
                FileOutputStream libraryFileStream = new FileOutputStream( libraryFile );
                try {
                    ByteStreams.copy( libraryStream, libraryFileStream );
                }
                finally {
                    libraryFileStream.close();
                    libraryStream.close();
                }

                // Load the library from the temporary file.
                System.load( libraryFile.getAbsolutePath() );
                return true;
            }
            catch (@SuppressWarnings("ErrorNotRethrown") final IOException | UnsatisfiedLinkError e) {
                logger.wrn( e, "Couldn't load library: %s", libraryResource );

                if (libraryFile != null && libraryFile.exists() && !libraryFile.delete())
                    logger.wrn( "Couldn't clean up library file: %s", libraryFile );
                libraryFile = null;
            }
        }

        return false;
    }

    @Nonnull
    private static Set<String> getLibraryResources(final String library) {
        // Standardize system naming in accordance with masterpassword-core.
        Sys system = Sys.findCurrent();

        // Standardize architecture naming in accordance with masterpassword-core.
        Collection<Arch> architectures = new LinkedHashSet<>();
        architectures.add( Arch.findCurrent() );
        architectures.addAll( Arrays.asList( Arch.values() ) );

        ImmutableSet.Builder<String> resources = ImmutableSet.builder();
        for (final Arch arch : architectures)
            resources.add( Joiner.on( RESOURCE_SEPARATOR ).join( "", NATIVES_PATH, system, arch, library ) );

        return resources.build();
    }

    private enum Sys implements Predicate<String> {
        windows {
            @Override
            public boolean test(final String system) {
                return system.contains( "windows" );
            }
        },
        macos {
            @Override
            public boolean test(final String system) {
                return system.contains( "mac os x" ) || system.contains( "darwin" ) || system.contains( "osx" );
            }
        },
        linux {
            @Override
            public boolean test(final String system) {
                return system.contains( "linux" );
            }
        };

        @Nonnull
        public static Sys findCurrent() {
            return find( System.getProperty( "os.name" ) );
        }

        @Nonnull
        public static Sys find(@Nullable String name) {
            if (name != null) {
                name = name.toLowerCase( Locale.ROOT );

                for (final Sys sys : values())
                    if (sys.test( name ))
                        return sys;
            }

            return linux;
        }
    }


    private enum Arch implements Predicate<String> {
        arm {
            @Override
            public boolean test(final String architecture) {
                return ImmutableList.of( "arm", "arm-v7", "armv7", "arm32" ).contains( architecture );
            }
        },
        arm64 {
            @Override
            public boolean test(final String architecture) {
                return architecture.startsWith( "arm" ) && !arm.test( architecture );
            }
        },
        x86_64 {
            @Override
            public boolean test(final String architecture) {
                return ImmutableList.of( "x86_64", "amd64", "x64", "x86-64" ).contains( architecture );
            }
        },
        x86 {
            @Override
            public boolean test(final String architecture) {
                return ImmutableList.of( "x86", "i386", "i686" ).contains( architecture );
            }
        };

        @Nonnull
        public static Arch findCurrent() {
            return find( System.getProperty( "os.arch" ) );
        }

        @Nonnull
        public static Arch find(@Nullable String name) {
            if (name != null) {
                name = name.toLowerCase( Locale.ROOT );

                for (final Arch arch : values())
                    if (arch.test( name ))
                        return arch;
            }

            return x86;
        }
    }
}
