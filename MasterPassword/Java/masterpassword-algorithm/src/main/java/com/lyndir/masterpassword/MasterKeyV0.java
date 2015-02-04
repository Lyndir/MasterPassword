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
import javax.annotation.Nullable;


/**
 * bugs:
 * - does math with chars whose signedness was platform-dependent.
 * - miscounted the byte-length fromInt multi-byte site names.
 * - miscounted the byte-length fromInt multi-byte full names.
 *
 * @author lhunath, 2014-08-30
 */
public class MasterKeyV0 extends MasterKey {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MasterKeyV0.class );

    protected final int                          MP_N         = 32768;
    protected final int                          MP_r         = 8;
    protected final int                          MP_p         = 2;
    protected final int                          MP_dkLen     = 64;
    protected final int                          MP_intLen    = 32;
    protected final Charset                      MP_charset   = Charsets.UTF_8;
    protected final ByteOrder                    MP_byteOrder = ByteOrder.BIG_ENDIAN;
    protected final MessageDigests               MP_hash      = MessageDigests.SHA256;
    protected final MessageAuthenticationDigests MP_mac       = MessageAuthenticationDigests.HmacSHA256;

    public MasterKeyV0(final String fullName) {
        super( fullName );
    }

    @Override
    protected Version getAlgorithm() {

        return Version.V0;
    }

    @Nullable
    @Override
    protected byte[] deriveKey(final String masterPassword) {
        String fullName = getFullName();
        byte[] fullNameBytes = fullName.getBytes( MP_charset );
        byte[] fullNameLengthBytes = bytesForInt( fullName.length() );

        String mpKeyScope = MPSiteVariant.Password.getScope();
        byte[] masterKeySalt = Bytes.concat( mpKeyScope.getBytes( MP_charset ), fullNameLengthBytes, fullNameBytes );
        logger.trc( "key scope: %s", mpKeyScope );
        logger.trc( "masterKeySalt ID: %s", CodeUtils.encodeHex( idForBytes( masterKeySalt ) ) );

        try {
            return SCrypt.scrypt( masterPassword.getBytes( MP_charset ), masterKeySalt, MP_N, MP_r, MP_p, MP_dkLen );
        }
        catch (GeneralSecurityException e) {
            logger.bug( e );
            return null;
        }
    }

    public String encode(final String siteName, final MPSiteType siteType, int siteCounter, final MPSiteVariant siteVariant,
                         @Nullable final String siteContext) {
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
        byte[] siteNameLengthBytes = bytesForInt( siteName.length() );
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

        byte[] sitePasswordSeed = MP_mac.of( getMasterKey(), sitePasswordInfo );
        logger.trc( "sitePasswordSeed ID: %s", CodeUtils.encodeHex( idForBytes( sitePasswordSeed ) ) );

        Preconditions.checkState( sitePasswordSeed.length > 0 );
        int templateIndex = sitePasswordSeed[0];
        MPTemplate template = siteType.getTemplateAtRollingIndex( templateIndex );
        logger.trc( "type %s, template: %s", siteType, template.getTemplateString() );

        StringBuilder password = new StringBuilder( template.length() );
        for (int i = 0; i < template.length(); ++i) {
            int characterIndex = sitePasswordSeed[i + 1];
            MPTemplateCharacterClass characterClass = template.getCharacterClassAtIndex( i );
            char passwordCharacter = characterClass.getCharacterAtRollingIndex( characterIndex );
            logger.trc( "class %c, index %d (0x%02X) -> character: %c", characterClass.getIdentifier(), characterIndex,
                        sitePasswordSeed[i + 1], passwordCharacter );

            password.append( passwordCharacter );
        }

        return password.toString();
    }

    @Override
    protected byte[] bytesForInt(final int integer) {
        return ByteBuffer.allocate( MP_intLen / Byte.SIZE ).order( MP_byteOrder ).putInt( integer ).array();
    }

    @Override
    protected byte[] idForBytes(final byte[] bytes) {
        return MP_hash.of( bytes );
    }
}
