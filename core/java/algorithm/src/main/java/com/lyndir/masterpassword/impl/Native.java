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

import com.google.common.io.ByteStreams;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.io.*;


/**
 * @author lhunath, 2018-05-22
 */
public final class Native {
    private static final Logger logger = Logger.get( Native.class );

    private static final char   FILE_DOT     = '.';
    private static final String NATIVES_PATH = "";

    @SuppressWarnings({ "HardcodedFileSeparator", "LoadLibraryWithNonConstantString" })
    public static void load(final Class<?> context, final String name) {
        try {
            String      library          = System.mapLibraryName( name );
            int         libraryDot       = library.lastIndexOf( FILE_DOT );
            String      libraryName      = (libraryDot > 0)? library.substring( 0, libraryDot ): library;
            String      libraryExtension = (libraryDot > 0)? library.substring( libraryDot ): "lib";
            String      libraryResource  = String.format( "%s/%s", NATIVES_PATH, library );
            InputStream libraryStream    = context.getResourceAsStream( libraryResource );
            if (libraryStream == null)
                throw new IllegalStateException(
                        "Library: " + name + " (" + libraryResource + "), not found in class loader for: " + context );

            File libraryFile = File.createTempFile( "libmpw", ".dylib" );
            ByteStreams.copy( libraryStream, new FileOutputStream( libraryFile ) );
            System.load( libraryFile.getAbsolutePath() );
            libraryFile.deleteOnExit();
            if (!libraryFile.delete())
                logger.wrn( "Couldn't clean up library after loading: " + libraryFile );
        }
        catch (final IOException e) {
            throw new IllegalStateException( "Couldn't load library: " + name, e );
        }
    }
}
