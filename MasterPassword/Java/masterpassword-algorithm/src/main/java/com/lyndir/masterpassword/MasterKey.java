package com.lyndir.masterpassword;

import com.google.common.base.Charsets;
import com.google.common.base.Preconditions;
import com.google.common.primitives.Bytes;
import com.lambdaworks.crypto.SCrypt;
import com.lyndir.lhunath.opal.system.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.Charset;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-08-30
 */
public class MasterKey {

    public static final int    ALGORITHM = 1;
    public static final String VERSION   = "2.1";

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger                       logger       = Logger.get( MasterKey.class );
    private static final int                          MP_N         = 32768;
    private static final int                          MP_r         = 8;
    private static final int                          MP_p         = 2;
    private static final int                          MP_dkLen     = 64;
    private static final int                          MP_intLen    = 32;
    private static final Charset                      MP_charset   = Charsets.UTF_8;
    private static final ByteOrder                    MP_byteOrder = ByteOrder.BIG_ENDIAN;
    private static final MessageDigests               MP_hash      = MessageDigests.SHA256;
    private static final MessageAuthenticationDigests MP_mac       = MessageAuthenticationDigests.HmacSHA256;

    private final String fullName;
    private final byte[] masterKey;

    private boolean valid;

    public MasterKey(final String fullName, final String masterPassword) {

        this.fullName = fullName;
        logger.trc( "fullName: %s", fullName );
        logger.trc( "masterPassword: %s", masterPassword );

        long start = System.currentTimeMillis();
        byte[] userNameBytes = fullName.getBytes( MP_charset );
        byte[] userNameLengthBytes = bytesForInt( userNameBytes.length );

        String mpKeyScope = MPSiteVariant.Password.getScope();
        byte[] masterKeySalt = Bytes.concat( mpKeyScope.getBytes( MP_charset ), userNameLengthBytes, userNameBytes );
        logger.trc( "key scope: %s", mpKeyScope );
        logger.trc( "masterKeySalt ID: %s", CodeUtils.encodeHex( idForBytes( masterKeySalt ) ) );

        try {
            masterKey = SCrypt.scrypt( masterPassword.getBytes( MP_charset ), masterKeySalt, MP_N, MP_r, MP_p, MP_dkLen );
            valid = true;

            logger.trc( "masterKey ID: %s (derived in %.2fs)", CodeUtils.encodeHex( idForBytes( masterKey ) ),
                        (System.currentTimeMillis() - start) / 1000D );
        }
        catch (GeneralSecurityException e) {
            throw logger.bug( e );
        }
    }

    public String getFullName() {

        return fullName;
    }

    public byte[] getKeyID() {

        Preconditions.checkState( valid );
        return idForBytes( masterKey );
    }

    private byte[] getSubKey(final int subkeyLength) {

        Preconditions.checkState( valid );
        byte[] subkey = new byte[Math.min( subkeyLength, masterKey.length )];
        System.arraycopy( masterKey, 0, subkey, 0, subkey.length );

        return subkey;
    }

    public String encode(final String siteName, final MPSiteType siteType, int siteCounter, final MPSiteVariant siteVariant,
                         @Nullable final String siteContext) {
        Preconditions.checkState( valid );
        Preconditions.checkArgument( siteType.getTypeClass() == MPSiteTypeClass.Generated );
        Preconditions.checkArgument( !siteName.isEmpty() );

        logger.trc( "siteName: %s", siteName );
        logger.trc( "siteCounter: %d", siteCounter );
        logger.trc( "siteVariant: %d (%s)", siteVariant.ordinal(), siteVariant );
        logger.trc( "siteType: %d (%s)", siteType.ordinal(), siteType );

        if (siteCounter == 0)
            siteCounter = (int) (System.currentTimeMillis() / (300 * 1000)) * 300;

        String siteScope = siteVariant.getScope();
        byte[] siteNameBytes = siteName.getBytes( MP_charset );
        byte[] siteNameLengthBytes = bytesForInt( siteNameBytes.length );
        byte[] siteCounterBytes = bytesForInt( siteCounter );
        byte[] siteContextBytes = siteContext == null? null: siteContext.getBytes( MP_charset );
        byte[] siteContextLengthBytes = bytesForInt( siteContextBytes == null? 0: siteContextBytes.length );
        logger.trc( "site scope: %s, context: %s", siteScope, siteContext == null? "<empty>": siteContext );
        logger.trc( "seed from: hmac-sha256(masterKey, %s | %s | %s | %s | %s | %s)", siteScope, CodeUtils.encodeHex( siteNameLengthBytes ),
                    siteName, CodeUtils.encodeHex( siteCounterBytes ), CodeUtils.encodeHex( siteContextLengthBytes ),
                    siteContext == null? "(null)": siteContext );

        byte[] sitePasswordInfo = Bytes.concat( siteScope.getBytes( MP_charset ), siteNameLengthBytes, siteNameBytes, siteCounterBytes );
        if (siteContextBytes != null)
            sitePasswordInfo = Bytes.concat( sitePasswordInfo, siteContextLengthBytes, siteContextBytes );
        logger.trc( "sitePasswordInfo ID: %s", CodeUtils.encodeHex( idForBytes( sitePasswordInfo ) ) );

        byte[] sitePasswordSeed = MP_mac.of( masterKey, sitePasswordInfo );
        logger.trc( "sitePasswordSeed ID: %s", CodeUtils.encodeHex( idForBytes( sitePasswordSeed ) ) );

        Preconditions.checkState( sitePasswordSeed.length > 0 );
        int templateIndex = sitePasswordSeed[0] & 0xFF; // Mask the integer's sign.
        MPTemplate template = siteType.getTemplateAtRollingIndex( templateIndex );
        logger.trc( "type %s, template: %s", siteType, template.getTemplateString() );

        StringBuilder password = new StringBuilder( template.length() );
        for (int i = 0; i < template.length(); ++i) {
            int characterIndex = sitePasswordSeed[i + 1] & 0xFF; // Mask the integer's sign.
            MPTemplateCharacterClass characterClass = template.getCharacterClassAtIndex( i );
            char passwordCharacter = characterClass.getCharacterAtRollingIndex( characterIndex );
            logger.trc( "class %c, index %d (0x%02X) -> character: %c", characterClass.getIdentifier(), characterIndex,
                        sitePasswordSeed[i + 1], passwordCharacter );

            password.append( passwordCharacter );
        }

        return password.toString();
    }

    public void invalidate() {

        valid = false;
        Arrays.fill( masterKey, (byte) 0 );
    }

    private static byte[] bytesForInt(final int integer) {
        return ByteBuffer.allocate( MP_intLen / Byte.SIZE ).order( MP_byteOrder ).putInt( integer ).array();
    }

    private static byte[] idForBytes(final byte[] bytes) {
        return MP_hash.of( bytes );
    }
}
