package com.lyndir.lhunath.masterpassword;

import com.google.common.base.Charsets;
import com.google.common.base.Preconditions;
import com.google.common.primitives.Bytes;
import com.lambdaworks.crypto.SCrypt;
import com.lyndir.lhunath.opal.crypto.CryptUtils;
import com.lyndir.lhunath.opal.system.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.Charset;
import java.security.GeneralSecurityException;


/**
 * Implementation of the Master Password algorithm.
 *
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public abstract class MasterPassword {

    static final         Logger                       logger       = Logger.get( MasterPassword.class );
    private static final int                          MP_N         = 32768;
    private static final int                          MP_r         = 8;
    private static final int                          MP_p         = 2;
    private static final int                          MP_dkLen     = 64;
    private static final Charset                      MP_charset   = Charsets.UTF_8;
    private static final ByteOrder                    MP_byteOrder = ByteOrder.BIG_ENDIAN;
    private static final MessageDigests               MP_hash      = MessageDigests.SHA256;
    private static final MessageAuthenticationDigests MP_mac       = MessageAuthenticationDigests.HmacSHA256;
    private static final MPTemplates                  templates    = MPTemplates.loadFromPList( "templates.plist" );

    public static byte[] keyForPassword(final String password, final String username) {

        long start = System.currentTimeMillis();
        byte[] nusernameLengthBytes = ByteBuffer.allocate( Integer.SIZE / Byte.SIZE )
                                                .order( MP_byteOrder )
                                                .putInt( username.length() )
                                                .array();
        byte[] salt = Bytes.concat( "com.lyndir.masterpassword".getBytes( MP_charset ), //
                                    nusernameLengthBytes, //
                                    username.getBytes( MP_charset ) );

        try {
            byte[] key = SCrypt.scrypt( password.getBytes( MP_charset ), salt, MP_N, MP_r, MP_p, MP_dkLen );
            logger.trc( "User: %s, password: %s derives to key ID: %s (took %.2fs)", username, password,
                        CodeUtils.encodeHex( keyIDForKey( key ) ), (double) (System.currentTimeMillis() - start) / 1000 );

            return key;
        }
        catch (GeneralSecurityException e) {
            throw logger.bug( e );
        }
    }

    public static byte[] subkeyForKey(final byte[] key, final int subkeyLength) {

        byte[] subkey = new byte[Math.min( subkeyLength, key.length )];
        System.arraycopy( key, 0, subkey, 0, subkey.length );

        return subkey;
    }

    public static byte[] keyIDForPassword(final String password, final String username) {

        return keyIDForKey( keyForPassword( password, username ) );
    }

    public static byte[] keyIDForKey(final byte[] key) {

        return MP_hash.of( key );
    }

    public static String generateContent(final MPElementType type, final String name, final byte[] key, int counter) {

        Preconditions.checkArgument( type.getTypeClass() == MPElementTypeClass.Generated );
        Preconditions.checkArgument( !name.isEmpty() );
        Preconditions.checkArgument( key.length > 0 );

        if (counter == 0)
            counter = (int) (System.currentTimeMillis() / (300 * 1000)) * 300;

        byte[] nameLengthBytes = ByteBuffer.allocate( Integer.SIZE / Byte.SIZE ).order( MP_byteOrder ).putInt( name.length() ).array();
        byte[] counterBytes = ByteBuffer.allocate( Integer.SIZE / Byte.SIZE ).order( MP_byteOrder ).putInt( counter ).array();
        logger.trc( "seed from: hmac-sha256(%s, 'com.lyndir.masterpassword' | %s | %s | %s)", CryptUtils.encodeBase64( key ),
                    CodeUtils.encodeHex( nameLengthBytes ), name, CodeUtils.encodeHex( counterBytes ) );
        byte[] seed = MP_mac.of( key, Bytes.concat( "com.lyndir.masterpassword".getBytes( MP_charset ), //
                                                    nameLengthBytes, //
                                                    name.getBytes( MP_charset ), //
                                                    counterBytes ) );
        logger.trc( "seed is: %s", CryptUtils.encodeBase64( seed ) );

        Preconditions.checkState( seed.length > 0 );
        int templateIndex = seed[0] & 0xFF; // Mask the integer's sign.
        MPTemplate template = templates.getTemplateForTypeAtRollingIndex( type, templateIndex );
        logger.trc( "type: %s, template: %s", type, template );

        StringBuilder password = new StringBuilder( template.length() );
        for (int i = 0; i < template.length(); ++i) {
            int characterIndex = seed[i + 1] & 0xFF; // Mask the integer's sign.
            MPTemplateCharacterClass characterClass = template.getCharacterClassAtIndex( i );
            char passwordCharacter = characterClass.getCharacterAtRollingIndex( characterIndex );
            logger.trc( "class: %s, index: %d, byte: 0x%02X, chosen password character: %s", characterClass, characterIndex, seed[i + 1],
                        passwordCharacter );

            password.append( passwordCharacter );
        }

        return password.toString();
    }

    public static void main(final String... arguments) {

        String masterPassword = "test-mp";
        String username = "test-user";
        String siteName = "test-site";
        MPElementType siteType = MPElementType.GeneratedLong;
        int siteCounter = 42;

        String sitePassword = generateContent( siteType, siteName, keyForPassword( masterPassword, username ), siteCounter );

        logger.inf( "master password: %s, username: %s\nsite name: %s, site type: %s, site counter: %d\n    => site password: %s",
                    masterPassword, username, siteName, siteType, siteCounter, sitePassword );
    }
}
