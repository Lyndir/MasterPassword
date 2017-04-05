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
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.util.Arrays;
import javax.annotation.Nullable;


/**
 * bugs:
 * - no known issues.
 *
 * @author lhunath, 2014-08-30
 */
public class MasterKeyV3 extends MasterKeyV2 {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MasterKeyV3.class );

    public MasterKeyV3(final String fullName) {
        super( fullName );
    }

    @Override
    public Version getAlgorithmVersion() {

        return Version.V3;
    }

    @Nullable
    @Override
    protected byte[] deriveKey(final char[] masterPassword) {
        byte[] fullNameBytes = getFullName().getBytes( MPConstant.mpw_charset );
        byte[] fullNameLengthBytes = bytesForInt( fullNameBytes.length );

        String mpKeyScope = MPSiteVariant.Password.getScope();
        byte[] masterKeySalt = Bytes.concat( mpKeyScope.getBytes( MPConstant.mpw_charset ), fullNameLengthBytes, fullNameBytes );
        logger.trc( "key scope: %s", mpKeyScope );
        logger.trc( "masterKeySalt ID: %s", CodeUtils.encodeHex( idForBytes( masterKeySalt ) ) );

        ByteBuffer mpBytesBuf = MPConstant.mpw_charset.encode( CharBuffer.wrap( masterPassword ) );
        byte[] mpBytes = new byte[mpBytesBuf.remaining()];
        mpBytesBuf.get( mpBytes, 0, mpBytes.length );
        Arrays.fill( mpBytesBuf.array(), (byte) 0 );

        return scrypt( masterKeySalt, mpBytes );
    }
}
