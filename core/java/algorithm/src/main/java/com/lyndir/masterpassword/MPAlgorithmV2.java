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

import com.google.common.primitives.Bytes;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.CodeUtils;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-08-30
 * @see MPMasterKey.Version#V2
 */
public class MPAlgorithmV2 extends MPAlgorithmV1 {

    @Override
    public byte[] siteKey(final byte[] masterKey, final String siteName, UnsignedInteger siteCounter, final MPKeyPurpose keyPurpose,
                          @Nullable final String keyContext) {

        String keyScope = keyPurpose.getScope();
        logger.trc( "keyScope: %s", keyScope );

        // OTP counter value.
        if (siteCounter.longValue() == 0)
            siteCounter = UnsignedInteger.valueOf( (System.currentTimeMillis() / (mpw_otp_window() * 1000)) * mpw_otp_window() );

        // Calculate the site seed.
        byte[] siteNameBytes         = siteName.getBytes( mpw_charset() );
        byte[] siteNameLengthBytes   = toBytes( siteNameBytes.length );
        byte[] siteCounterBytes      = toBytes( siteCounter );
        byte[] keyContextBytes       = ((keyContext == null) || keyContext.isEmpty())? null: keyContext.getBytes( mpw_charset() );
        byte[] keyContextLengthBytes = (keyContextBytes == null)? null: toBytes( keyContextBytes.length );
        logger.trc( "siteSalt: keyScope=%s | #siteName=%s | siteName=%s | siteCounter=%s | #keyContext=%s | keyContext=%s",
                    keyScope, CodeUtils.encodeHex( siteNameLengthBytes ), siteName, CodeUtils.encodeHex( siteCounterBytes ),
                    (keyContextLengthBytes == null)? null: CodeUtils.encodeHex( keyContextLengthBytes ), keyContext );

        byte[] sitePasswordInfo = Bytes.concat( keyScope.getBytes( mpw_charset() ), siteNameLengthBytes, siteNameBytes, siteCounterBytes );
        if (keyContextBytes != null)
            sitePasswordInfo = Bytes.concat( sitePasswordInfo, keyContextLengthBytes, keyContextBytes );
        logger.trc( "  => siteSalt.id: %s", CodeUtils.encodeHex( toID( sitePasswordInfo ) ) );

        logger.trc( "siteKey: hmac-sha256( masterKey.id=%s, siteSalt )", CodeUtils.encodeHex( toID( masterKey ) ) );
        byte[] sitePasswordSeedBytes = mpw_digest().of( masterKey, sitePasswordInfo );
        logger.trc( "  => siteKey.id: %s", CodeUtils.encodeHex( toID( sitePasswordSeedBytes ) ) );

        return sitePasswordSeedBytes;
    }

    // Configuration

    @Override
    public MPMasterKey.Version version() {
        return MPMasterKey.Version.V2;
    }
}
