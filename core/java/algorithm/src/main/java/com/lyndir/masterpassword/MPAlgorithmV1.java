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
import javax.annotation.Nullable;


/**
 * @see MPMasterKey.Version#V1
 *
 * @author lhunath, 2014-08-30
 */
public class MPAlgorithmV1 extends MPAlgorithmV0 {

    @Override
    public MPMasterKey.Version getAlgorithmVersion() {

        return MPMasterKey.Version.V1;
    }

    @Override
    public String sitePasswordFromTemplate(final byte[] masterKey, final byte[] siteKey, final MPResultType resultType, @Nullable final String resultParam) {

        logger.trc( "-- mpw_siteResult (algorithm: %u)", getAlgorithmVersion().toInt() );
        logger.trc( "resultType: %d (%s)", resultType.toInt(), resultType.getShortName() );
        logger.trc( "resultParam: %s", resultParam );

        // Determine the template.
        Preconditions.checkState( siteKey.length > 0 );
        int templateIndex = siteKey[0] & 0xFF; // Convert to unsigned int.
        MPTemplate template = resultType.getTemplateAtRollingIndex( templateIndex );
        logger.trc( "template: %u => %s", templateIndex, template.getTemplateString() );

        // Encode the password from the seed using the template.
        StringBuilder password = new StringBuilder( template.length() );
        for (int i = 0; i < template.length(); ++i) {
            int characterIndex = siteKey[i + 1] & 0xFF; // Convert to unsigned int.
            MPTemplateCharacterClass characterClass = template.getCharacterClassAtIndex( i );
            char passwordCharacter = characterClass.getCharacterAtRollingIndex( characterIndex );
            logger.trc( "  - class: %c, index: %3u (0x%02hhX) => character: %c",
                        characterClass.getIdentifier(), characterIndex, siteKey[i + 1], passwordCharacter );

            password.append( passwordCharacter );
        }
        logger.trc( "  => password: %s", password );

        return password.toString();
    }
}
