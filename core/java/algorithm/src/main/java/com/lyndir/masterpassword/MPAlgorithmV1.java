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

package com.lyndir.masterpassword;

import com.google.common.base.Preconditions;
import com.google.common.primitives.UnsignedBytes;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-08-30
 * @see MPMasterKey.Version#V1
 */
public class MPAlgorithmV1 extends MPAlgorithmV0 {

    @Override
    public MPMasterKey.Version getAlgorithmVersion() {

        return MPMasterKey.Version.V1;
    }

    @Override
    public String sitePasswordFromTemplate(final byte[] masterKey, final byte[] siteKey, final MPResultType resultType,
                                           @Nullable final String resultParam) {

        // Determine the template.
        Preconditions.checkState( siteKey.length > 0 );
        int        templateIndex = UnsignedBytes.toInt( siteKey[0] );
        MPTemplate template      = resultType.getTemplateAtRollingIndex( templateIndex );
        logger.trc( "template: %d => %s", templateIndex, template.getTemplateString() );

        // Encode the password from the seed using the template.
        StringBuilder password = new StringBuilder( template.length() );
        for (int i = 0; i < template.length(); ++i) {
            int                      characterIndex    = UnsignedBytes.toInt( siteKey[i + 1] );
            MPTemplateCharacterClass characterClass    = template.getCharacterClassAtIndex( i );
            char                     passwordCharacter = characterClass.getCharacterAtRollingIndex( characterIndex );
            logger.trc( "  - class: %c, index: %3d (0x%2H) => character: %c",
                        characterClass.getIdentifier(), characterIndex, siteKey[i + 1], passwordCharacter );

            password.append( passwordCharacter );
        }
        logger.trc( "  => password: %s", password );

        return password.toString();
    }
}
