package com.lyndir.masterpassword;

import com.google.common.base.Charsets;
import com.google.common.base.Preconditions;
import com.google.common.io.CharSource;
import com.google.common.io.CharStreams;
import com.google.common.primitives.Bytes;
import com.lambdaworks.crypto.SCrypt;
import com.lyndir.lhunath.opal.crypto.CryptUtils;
import com.lyndir.lhunath.opal.system.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.Charset;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import javax.xml.stream.events.Characters;


/**
 * @author lhunath, 2014-08-30
 */
public class MasterKey {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger                       logger       = Logger.get( MasterKey.class );
    private static final int                          MP_N         = 32768;
    private static final int                          MP_r         = 8;
    private static final int                          MP_p         = 2;
    private static final int                          MP_dkLen     = 64;
    private static final Charset                      MP_charset   = Charsets.UTF_8;
    private static final ByteOrder                    MP_byteOrder = ByteOrder.BIG_ENDIAN;
    private static final MessageDigests               MP_hash      = MessageDigests.SHA256;
    private static final MessageAuthenticationDigests MP_mac       = MessageAuthenticationDigests.HmacSHA256;
    private static final MPTemplates                  templates    = MPTemplates.load();

    private final String userName;
    private final byte[] key;

    private boolean valid;

    public MasterKey(final String userName, final String masterPassword) {

        this.userName = userName;

        long start = System.currentTimeMillis();
        byte[] userNameLengthBytes = ByteBuffer.allocate( Integer.SIZE / Byte.SIZE )
                                               .order( MP_byteOrder )
                                               .putInt( userName.length() )
                                               .array();
        byte[] salt = Bytes.concat( "com.lyndir.masterpassword".getBytes( MP_charset ), //
                                    userNameLengthBytes, userName.getBytes( MP_charset ) );

        try {
            key = SCrypt.scrypt( masterPassword.getBytes( MP_charset ), salt, MP_N, MP_r, MP_p, MP_dkLen );
            valid = true;

            logger.trc( "User: %s, master password derives to key ID: %s (took %.2fs)", //
                        userName, getKeyID(), (double) (System.currentTimeMillis() - start) / 1000 );
        }
        catch (GeneralSecurityException e) {
            throw logger.bug( e );
        }
    }

    public String getUserName() {

        return userName;
    }

    public String getKeyID() {

        Preconditions.checkState( valid );
        return CodeUtils.encodeHex( MP_hash.of( key ) );
    }

    private byte[] getSubkey(final int subkeyLength) {

        Preconditions.checkState( valid );
        byte[] subkey = new byte[Math.min( subkeyLength, key.length )];
        System.arraycopy( key, 0, subkey, 0, subkey.length );

        return subkey;
    }

    public String encode(final String name, final MPElementType type, int counter) {

        Preconditions.checkState( valid );
        Preconditions.checkArgument( type.getTypeClass() == MPElementTypeClass.Generated );
        Preconditions.checkArgument( !name.isEmpty() );

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

    public void invalidate() {

        valid = false;
        Arrays.fill( key, (byte) 0 );
    }
}
