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

package com.lyndir.masterpassword.model;

import com.google.common.base.*;
import com.google.common.io.CharStreams;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.lhunath.opal.system.util.ConversionUtils;
import com.lyndir.masterpassword.*;
import java.io.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.annotation.Nonnull;
import org.joda.time.DateTime;


/**
 * @author lhunath, 14-12-07
 */
public class MPFlatUnmarshaller implements MPUnmarshaller {

    private static final Pattern[] unmarshallFormats = {
            Pattern.compile( "^([^ ]+) +(\\d+) +(\\d+)(:\\d+)? +([^\t]+)\t(.*)" ),
            Pattern.compile( "^([^ ]+) +(\\d+) +(\\d+)(:\\d+)?(:\\d+)? +([^\t]*)\t *([^\t]+)\t(.*)" ) };
    private static final Pattern   headerFormat      = Pattern.compile( "^#\\s*([^:]+): (.*)" );
    private static final Pattern   colon             = Pattern.compile( ":" );

    @Nonnull
    @Override
    public MPFileUser unmarshall(@Nonnull final File file)
            throws IOException {
        try (Reader reader = new InputStreamReader( new FileInputStream( file ), Charsets.UTF_8 )) {
            return unmarshall( CharStreams.toString( reader ) );
        }
    }

    @Nonnull
    @Override
    public MPFileUser unmarshall(@Nonnull final String content) {
        MPFileUser   user         = null;
        byte[]       keyID        = null;
        String       fullName     = null;
        int          mpVersion    = 0, importFormat = 0, avatar = 0;
        boolean      clearContent = false, headerStarted = false;
        MPResultType defaultType  = MPAlgorithm.mpw_default_type;

        //noinspection HardcodedLineSeparator
        for (final String line : Splitter.on( CharMatcher.anyOf( "\r\n" ) ).omitEmptyStrings().split( content ))
            // Header delimitor.
            if (line.startsWith( "##" ))
                if (!headerStarted)
                    // Starts the header.
                    headerStarted = true;
                else
                    // Ends the header.
                    user = new MPFileUser( fullName, keyID, MPMasterKey.Version.fromInt( mpVersion ), avatar, defaultType, new DateTime( 0 ) );

                // Comment.
            else if (line.startsWith( "#" )) {
                if (headerStarted && (user == null)) {
                    // In header.
                    Matcher headerMatcher = headerFormat.matcher( line );
                    if (headerMatcher.matches()) {
                        String name = headerMatcher.group( 1 ), value = headerMatcher.group( 2 );
                        if ("Full Name".equalsIgnoreCase( name ) || "User Name".equalsIgnoreCase( name ))
                            fullName = value;
                        else if ("Key ID".equalsIgnoreCase( name ))
                            keyID = CodeUtils.decodeHex( value );
                        else if ("Algorithm".equalsIgnoreCase( name ))
                            mpVersion = ConversionUtils.toIntegerNN( value );
                        else if ("Format".equalsIgnoreCase( name ))
                            importFormat = ConversionUtils.toIntegerNN( value );
                        else if ("Avatar".equalsIgnoreCase( name ))
                            avatar = ConversionUtils.toIntegerNN( value );
                        else if ("Passwords".equalsIgnoreCase( name ))
                            clearContent = "visible".equalsIgnoreCase( value );
                        else if ("Default Type".equalsIgnoreCase( name ))
                            defaultType = MPResultType.forType( ConversionUtils.toIntegerNN( value ) );
                    }
                }
            }

            // No comment.
            else if (user != null) {
                Matcher siteMatcher = unmarshallFormats[importFormat].matcher( line );
                if (!siteMatcher.matches())
                    return null;

                MPFileSite site;
                switch (importFormat) {
                    case 0:
                        site = new MPFileSite( user, //
                                               siteMatcher.group( 5 ), siteMatcher.group( 6 ), MPFileSite.DEFAULT_COUNTER,
                                               MPResultType.forType( ConversionUtils.toIntegerNN( siteMatcher.group( 3 ) ) ),
                                               MPMasterKey.Version.fromInt( ConversionUtils.toIntegerNN(
                                                   colon.matcher( siteMatcher.group( 4 ) ).replaceAll( "" ) ) ),
                                               null, null, null, ConversionUtils.toIntegerNN( siteMatcher.group( 2 ) ),
                                               MPConstant.dateTimeFormatter.parseDateTime( siteMatcher.group( 1 ) ).toInstant() );
                        break;

                    case 1:
                        site = new MPFileSite( user, //
                                               siteMatcher.group( 7 ), siteMatcher.group( 8 ),
                                               UnsignedInteger.valueOf( colon.matcher( siteMatcher.group( 5 ) ).replaceAll( "" ) ),
                                               MPResultType.forType( ConversionUtils.toIntegerNN( siteMatcher.group( 3 ) ) ),
                                               MPMasterKey.Version.fromInt( ConversionUtils.toIntegerNN(
                                                   colon.matcher( siteMatcher.group( 4 ) ).replaceAll( "" ) ) ),
                                               siteMatcher.group( 6 ), MPResultType.GeneratedName, null,
                                               ConversionUtils.toIntegerNN( siteMatcher.group( 2 ) ),
                                               MPConstant.dateTimeFormatter.parseDateTime( siteMatcher.group( 1 ) ).toInstant() );
                        break;

                    default:
                        throw new UnsupportedOperationException( "Unexpected format: " + importFormat );
                }

                user.addSite( site );
            }

        return Preconditions.checkNotNull( user, "No full header found in import file." );
    }
}
