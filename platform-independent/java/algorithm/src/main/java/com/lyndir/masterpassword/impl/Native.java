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

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.google.common.base.Joiner;
import com.google.common.collect.ImmutableList;
import com.google.common.io.ByteStreams;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.io.*;
import java.util.Locale;
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

    @SuppressWarnings({ "HardcodedFileSeparator", "LoadLibraryWithNonConstantString" })
    public static void load(final Class<?> context, final String name) {

        // Try to load the library using the native system.
        try {
            System.loadLibrary( name );
            return;
        }
        catch (@SuppressWarnings("ErrorNotRethrown") final UnsatisfiedLinkError ignored) {
        }

        // Try to find and open a stream to the packaged library resource.
        try {
            String      library          = System.mapLibraryName( name );
            int         libraryDot       = library.lastIndexOf( EXTENSION_SEPARATOR );
            String      libraryName      = (libraryDot > 0)? library.substring( 0, libraryDot ): library;
            String      libraryExtension = (libraryDot > 0)? library.substring( libraryDot ): ".lib";
            String      libraryResource  = getLibraryResource( library );
            InputStream libraryStream    = context.getResourceAsStream( libraryResource );
            if (libraryStream == null)
                throw new IllegalStateException(
                        "Library: " + name + " (" + libraryResource + "), not found in class loader for: " + context );

            // Write the library resource to a temporary file.
            File             libraryFile       = File.createTempFile( libraryName, libraryExtension );
            FileOutputStream libraryFileStream = new FileOutputStream( libraryFile );
            try {
                libraryFile.deleteOnExit();
                ByteStreams.copy( libraryStream, libraryFileStream );
            }
            finally {
                libraryFileStream.close();
                libraryStream.close();
            }

            // Load the library from the temporary file.
            System.load( libraryFile.getAbsolutePath() );
        }
        catch (final IOException e) {
            throw new IllegalStateException( "Couldn't extract library: " + name, e );
        }
    }

    @Nonnull
    private static String getLibraryResource(final String library) {
        String system       = ifNotNullElse( System.getProperty( "os.name" ), "linux" ).toLowerCase( Locale.ROOT );
        String architecture = ifNotNullElse( System.getProperty( "os.arch" ), "x86" ).toLowerCase( Locale.ROOT );

        // Standardize system naming in accordance with masterpassword-core.
        if (system.contains( "windows" ))
            system = "windows";
        else if (system.contains( "mac os x" ) || system.contains( "darwin" ) || system.contains( "osx" ))
            system = "macos";
        else
            system = "linux";

        // Standardize architecture naming in accordance with masterpassword-core.
        if (ImmutableList.of( "arm", "arm-v7", "armv7", "arm32" ).contains( architecture ))
            architecture = "arm";
        else if (architecture.startsWith( "arm" ))
            architecture = "arm64";
        else if (ImmutableList.of( "x86_64", "amd64", "x64", "x86-64" ).contains( architecture ))
            architecture = "x86_64";
        else
            architecture = "x86";

        return Joiner.on( RESOURCE_SEPARATOR ).join( "", NATIVES_PATH, system, architecture, library );
    }
}
