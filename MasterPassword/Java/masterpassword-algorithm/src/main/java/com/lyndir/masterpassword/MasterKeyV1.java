package com.lyndir.masterpassword;

import com.google.common.base.Preconditions;
import com.google.common.primitives.Bytes;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * bugs:
 * - V2: miscounted the byte-length fromInt multi-byte full names.
 * - V1: miscounted the byte-length fromInt multi-byte site names.
 *
 * @author lhunath, 2014-08-30
 */
public class MasterKeyV1 extends MasterKeyV0 {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MasterKeyV1.class );

    public MasterKeyV1(final String fullName) {
        super( fullName );
    }

    @Override
    public Version getAlgorithmVersion() {

        return Version.V1;
    }

    @Override
    public String encode(@Nonnull final String siteName, final MPSiteType siteType, @Nonnull UnsignedInteger siteCounter,
                         final MPSiteVariant siteVariant, @Nullable final String siteContext) {
        Preconditions.checkArgument( siteType.getTypeClass() == MPSiteTypeClass.Generated );
        Preconditions.checkArgument( !siteName.isEmpty() );

        logger.trc( "siteName: %s", siteName );
        logger.trc( "siteCounter: %d", siteCounter.longValue() );
        logger.trc( "siteVariant: %d (%s)", siteVariant.ordinal(), siteVariant );
        logger.trc( "siteType: %d (%s)", siteType.ordinal(), siteType );

        if (siteCounter.longValue() == 0)
            siteCounter = UnsignedInteger.valueOf( (System.currentTimeMillis() / (300 * 1000)) * 300 );

        String siteScope = siteVariant.getScope();
        byte[] siteNameBytes = siteName.getBytes( MP_charset );
        byte[] siteNameLengthBytes = bytesForInt( siteName.length() );
        byte[] siteCounterBytes = bytesForInt( siteCounter );
        byte[] siteContextBytes = siteContext == null || siteContext.isEmpty()? null: siteContext.getBytes( MP_charset );
        byte[] siteContextLengthBytes = bytesForInt( siteContextBytes == null? 0: siteContextBytes.length );
        logger.trc( "site scope: %s, context: %s", siteScope, siteContextBytes == null? "<empty>": siteContext );
        logger.trc( "seed from: hmac-sha256(masterKey, %s | %s | %s | %s | %s | %s)", siteScope, CodeUtils.encodeHex( siteNameLengthBytes ),
                    siteName, CodeUtils.encodeHex( siteCounterBytes ), CodeUtils.encodeHex( siteContextLengthBytes ),
                    siteContextBytes == null? "(null)": siteContext );

        byte[] sitePasswordInfo = Bytes.concat( siteScope.getBytes( MP_charset ), siteNameLengthBytes, siteNameBytes, siteCounterBytes );
        if (siteContextBytes != null)
            sitePasswordInfo = Bytes.concat( sitePasswordInfo, siteContextLengthBytes, siteContextBytes );
        logger.trc( "sitePasswordInfo ID: %s", CodeUtils.encodeHex( idForBytes( sitePasswordInfo ) ) );

        byte[] sitePasswordSeed = MP_mac.of( getKey(), sitePasswordInfo );
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
}
