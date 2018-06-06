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

import com.lyndir.masterpassword.MPAlgorithmException;
import com.lyndir.masterpassword.MPKeyUnavailableException;
import com.lyndir.masterpassword.model.MPConstant;
import javax.annotation.Nonnull;
import org.joda.time.Instant;


/**
 * @author lhunath, 2017-09-20
 */
@SuppressWarnings({ "HardcodedLineSeparator", "MagicCharacter" })
public class MPFlatMarshaller implements MPMarshaller {

    private static final int FORMAT = 1;

    @Nonnull
    @Override
    public String marshall(final MPFileUser user)
            throws MPKeyUnavailableException, MPMarshalException, MPAlgorithmException {
        StringBuilder content = new StringBuilder();
        content.append( "# Master Password site export\n" );
        content.append( "#     " ).append( user.getContentMode().description() ).append( '\n' );
        content.append( "# \n" );
        content.append( "##\n" );
        content.append( "# Format: " ).append( FORMAT ).append( '\n' );
        content.append( "# Date: " ).append( MPConstant.dateTimeFormatter.print( new Instant() ) ).append( '\n' );
        content.append( "# User Name: " ).append( user.getFullName() ).append( '\n' );
        content.append( "# Full Name: " ).append( user.getFullName() ).append( '\n' );
        content.append( "# Avatar: " ).append( user.getAvatar() ).append( '\n' );
        content.append( "# Key ID: " ).append( user.exportKeyID() ).append( '\n' );
        content.append( "# Algorithm: " ).append( user.getAlgorithm().version().toInt() ).append( '\n' );
        content.append( "# Default Type: " ).append( user.getDefaultType().getType() ).append( '\n' );
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
                                  MPConstant.dateTimeFormatter.print( site.getLastUsed() ), // lastUsed
                                  site.getUses(), // uses
                                  strf( "%d:%d:%d", //
                                        site.getResultType().getType(), // type
                                        site.getAlgorithm().version().toInt(), // algorithm
                                        site.getCounter().intValue() ), // counter
                                  ifNotNullElse( loginName, "" ), // loginName
                                  site.getName(), // siteName
                                  ifNotNullElse( password, "" ) // password
            ) );
        }

        return content.toString();
    }
}
