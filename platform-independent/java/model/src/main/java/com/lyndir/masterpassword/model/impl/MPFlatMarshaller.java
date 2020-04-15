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

package com.lyndir.masterpassword.model.impl;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Charsets;
import com.google.common.io.CharSink;
import com.lyndir.masterpassword.MPAlgorithmException;
import com.lyndir.masterpassword.MPKeyUnavailableException;
import com.lyndir.masterpassword.model.MPModelConstants;
import java.io.*;
import org.joda.time.Instant;


/**
 * @author lhunath, 2017-09-20
 */
@SuppressWarnings({ "HardcodedLineSeparator", "MagicCharacter" })
public class MPFlatMarshaller implements MPMarshaller {

    private static final int FORMAT = 1;

    @Override
    public void marshall(final MPFileUser user)
            throws IOException, MPKeyUnavailableException, MPMarshalException, MPAlgorithmException {
        if (!user.isComplete())
            throw new IllegalStateException( "Cannot marshall an incomplete user: " + user );

        StringBuilder content = new StringBuilder();
        content.append( "# Master Password site export\n" );
        content.append( "#     " ).append( user.getContentMode().description() ).append( '\n' );
        content.append( "# \n" );
        content.append( "##\n" );
        content.append( "# Format: " ).append( FORMAT ).append( '\n' );
        content.append( "# Date: " ).append( MPModelConstants.dateTimeFormatter.print( new Instant() ) ).append( '\n' );
        content.append( "# User Name: " ).append( user.getFullName() ).append( '\n' );
        content.append( "# Full Name: " ).append( user.getFullName() ).append( '\n' );
        content.append( "# Avatar: " ).append( user.getAvatar() ).append( '\n' );
        content.append( "# Key ID: " ).append( user.getKeyID() ).append( '\n' );
        content.append( "# Algorithm: " ).append( user.getAlgorithm().version().toInt() ).append( '\n' );
        content.append( "# Default Type: " ).append( user.getPreferences().getDefaultType().getType() ).append( '\n' );
        content.append( "# Passwords: " ).append( user.getContentMode().name() ).append( '\n' );
        content.append( "##\n" );
        content.append( "#\n" );
        content.append( "#               Last     Times  Password                      Login\t                     Site\tSite\n" );
        content.append( "#               used      used      type                       name\t                     name\tpassword\n" );

        for (final MPFileSite site : user.getSites()) {
            String loginName = site.getLoginState();
            String password  = site.getResultState();
            if (!user.getContentMode().isRedacted()) {
                loginName = site.getLogin();
                password = site.getResult();
            }

            content.append( strf( "%s  %8d  %8s  %25s\t%25s\t%s\n", //
                                  MPModelConstants.dateTimeFormatter.print( site.getLastUsed() ), // lastUsed
                                  site.getUses(), // uses
                                  strf( "%d:%d:%d", //
                                        site.getResultType().getType(), // type
                                        site.getAlgorithm().version().toInt(), // algorithm
                                        site.getCounter().intValue() ), // counter
                                  ifNotNullElse( loginName, "" ), // loginName
                                  site.getSiteName(), // siteName
                                  ifNotNullElse( password, "" ) // password
            ) );
        }

        new CharSink() {
            @Override
            public Writer openStream()
                    throws IOException {
                return new OutputStreamWriter( new FileOutputStream( user.getFile() ), Charsets.UTF_8 );
            }
        }.write( content.toString() );
    }
}
