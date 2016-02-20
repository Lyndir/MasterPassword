package com.lyndir.masterpassword;

import com.google.common.primitives.Bytes;
import com.lambdaworks.crypto.SCrypt;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.security.GeneralSecurityException;
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
        byte[] fullNameBytes = getFullName().getBytes( MP_charset );
        byte[] fullNameLengthBytes = bytesForInt( fullNameBytes.length );

        String mpKeyScope = MPSiteVariant.Password.getScope();
        byte[] masterKeySalt = Bytes.concat( mpKeyScope.getBytes( MP_charset ), fullNameLengthBytes, fullNameBytes );
        logger.trc( "key scope: %s", mpKeyScope );
        logger.trc( "masterKeySalt ID: %s", CodeUtils.encodeHex( idForBytes( masterKeySalt ) ) );

        ByteBuffer mpBytesBuf = MP_charset.encode( CharBuffer.wrap( masterPassword ) );
        byte[] mpBytes = new byte[mpBytesBuf.remaining()];
        mpBytesBuf.get( mpBytes, 0, mpBytes.length );
        Arrays.fill( mpBytesBuf.array(), (byte) 0 );

        return scrypt( masterKeySalt, mpBytes );
    }
}
