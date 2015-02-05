package com.lyndir.masterpassword;

import com.google.common.primitives.Bytes;
import com.lambdaworks.crypto.SCrypt;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.lhunath.opal.system.logging.Logger;
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
    protected Version getAlgorithm() {

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

        CharBuffer mpChars = CharBuffer.wrap( masterPassword );
        byte[] mpBytes = MP_charset.encode( mpChars ).array();
        try {
            return SCrypt.scrypt( mpBytes, masterKeySalt, MP_N, MP_r, MP_p, MP_dkLen );
        }
        catch (GeneralSecurityException e) {
            logger.bug( e );
            return null;
        }
        finally {
            Arrays.fill( mpBytes, (byte) 0 );
        }
    }
}
