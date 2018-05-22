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

package com.lyndir.masterpassword.impl;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Charsets;
import com.google.common.base.Preconditions;
import com.google.common.io.BaseEncoding;
import com.google.common.primitives.Bytes;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import java.nio.*;
import java.nio.charset.Charset;
import java.security.*;
import java.security.spec.AlgorithmParameterSpec;
import java.util.Arrays;
import javax.annotation.Nullable;
import javax.crypto.*;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;


/**
 * @author lhunath, 2014-08-30
 * @see MPAlgorithm.Version#V0
 */
@SuppressWarnings("NewMethodNamingConvention")
public class MPAlgorithmV0 extends MPAlgorithm {

    @SuppressWarnings("HardcodedFileSeparator")
    protected static final String AES_TRANSFORMATION = "AES/CBC/PKCS5Padding";
    protected static final int    AES_BLOCKSIZE      = 128 /* bit */;

    static {
        Native.load( MPAlgorithmV0.class, "mpw" );
    }

    public final Version version = MPAlgorithm.Version.V0;

    protected final Logger logger = Logger.get( getClass() );

    @Override
    public byte[] masterKey(final String fullName, final char[] masterPassword) {

        byte[] fullNameBytes       = fullName.getBytes( mpw_charset() );
        byte[] fullNameLengthBytes = toBytes( fullName.length() );

        String keyScope = MPKeyPurpose.Authentication.getScope();
        logger.trc( "keyScope: %s", keyScope );

        // Calculate the master key salt.
        logger.trc( "masterKeySalt: keyScope=%s | #fullName=%s | fullName=%s",
                    keyScope, CodeUtils.encodeHex( fullNameLengthBytes ), fullName );
        byte[] masterKeySalt = Bytes.concat( keyScope.getBytes( mpw_charset() ), fullNameLengthBytes, fullNameBytes );
        logger.trc( "  => masterKeySalt.id: %s", CodeUtils.encodeHex( toID( masterKeySalt ) ) );

        // Calculate the master key.
        logger.trc( "masterKey: scrypt( masterPassword, masterKeySalt, N=%d, r=%d, p=%d )",
                    scrypt_N(), scrypt_r(), scrypt_p() );
        byte[] masterPasswordBytes = toBytes( masterPassword );
        byte[] masterKey           = scrypt( masterPasswordBytes, masterKeySalt, mpw_dkLen() );
        Arrays.fill( masterKeySalt, (byte) 0 );
        Arrays.fill( masterPasswordBytes, (byte) 0 );
        if (masterKey == null)
            throw new IllegalStateException( "Could not derive master key." );
        logger.trc( "  => masterKey.id: %s", CodeUtils.encodeHex( toID( masterKey ) ) );

        return masterKey;
    }

    @Nullable
    protected byte[] scrypt(final byte[] secret, final byte[] salt, final int keySize) {
        byte[] buffer = new byte[keySize];
        if (_scrypt(
                secret, secret.length, salt, salt.length,
                scrypt_N(), scrypt_r(), scrypt_p(), buffer, buffer.length ) < 0)
            return null;

        return buffer;
    }

    protected native int _scrypt(byte[] passwd, int passwdlen, byte[] salt, int saltlen, int N, int r, int p, byte[] buf, int buflen);

    @Override
    public byte[] siteKey(final byte[] masterKey, final String siteName, UnsignedInteger siteCounter,
                          final MPKeyPurpose keyPurpose, @Nullable final String keyContext) {

        String keyScope = keyPurpose.getScope();
        logger.trc( "keyScope: %s", keyScope );

        // OTP counter value.
        if (siteCounter.longValue() == 0)
            siteCounter = UnsignedInteger.valueOf( (System.currentTimeMillis() / (mpw_otp_window() * 1000)) * mpw_otp_window() );

        // Calculate the site seed.
        byte[] siteNameBytes         = siteName.getBytes( mpw_charset() );
        byte[] siteNameLengthBytes   = toBytes( siteName.length() );
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

    @Override
    public String siteResult(final byte[] masterKey, final byte[] siteKey, final String siteName, final UnsignedInteger siteCounter,
                             final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                             final MPResultType resultType, @Nullable final String resultParam) {

        switch (resultType.getTypeClass()) {
            case Template:
                return siteResultFromTemplate( masterKey, siteKey, resultType, resultParam );
            case Stateful:
                return siteResultFromState( masterKey, siteKey, resultType, Preconditions.checkNotNull( resultParam ) );
            case Derive:
                return siteResultFromDerive( masterKey, siteKey, resultType, resultParam );
        }

        throw logger.bug( "Unsupported result type class: %s", resultType.getTypeClass() );
    }

    @Override
    public String siteResultFromTemplate(final byte[] masterKey, final byte[] siteKey,
                                         final MPResultType resultType, @Nullable final String resultParam) {

        int[] _siteKey = new int[siteKey.length];
        for (int i = 0; i < siteKey.length; ++i) {
            ByteBuffer buf = ByteBuffer.allocate( Integer.SIZE / Byte.SIZE ).order( mpw_byteOrder() );
            Arrays.fill( buf.array(), (byte) ((siteKey[i] > 0)? 0x00: 0xFF) );
            buf.position( 2 );
            buf.put( siteKey[i] ).rewind();
            _siteKey[i] = buf.getInt() & 0xFFFF;
        }

        // Determine the template.
        Preconditions.checkState( _siteKey.length > 0 );
        int        templateIndex = _siteKey[0];
        MPTemplate template      = resultType.getTemplateAtRollingIndex( templateIndex );
        logger.trc( "template: %d => %s", templateIndex, template.getTemplateString() );

        // Encode the password from the seed using the template.
        StringBuilder password = new StringBuilder( template.length() );
        for (int i = 0; i < template.length(); ++i) {
            int                      characterIndex    = _siteKey[i + 1];
            MPTemplateCharacterClass characterClass    = template.getCharacterClassAtIndex( i );
            char                     passwordCharacter = characterClass.getCharacterAtRollingIndex( characterIndex );
            logger.trc( "  - class: %c, index: %5d (0x%2H) => character: %c",
                        characterClass.getIdentifier(), characterIndex, _siteKey[i + 1], passwordCharacter );

            password.append( passwordCharacter );
        }
        logger.trc( "  => password: %s", password );

        return password.toString();
    }

    @Override
    public String siteResultFromState(final byte[] masterKey, final byte[] siteKey,
                                      final MPResultType resultType, final String resultParam) {

        Preconditions.checkNotNull( resultParam );
        Preconditions.checkArgument( !resultParam.isEmpty() );

        // Base64-decode
        byte[] cipherBuf = BaseEncoding.base64().decode( resultParam );
        logger.trc( "b64 decoded: %d bytes = %s", cipherBuf.length, CodeUtils.encodeHex( cipherBuf ) );

        // Decrypt
        byte[] plainBuf  = aes_decrypt( cipherBuf, masterKey );
        String plainText = mpw_charset().decode( ByteBuffer.wrap( plainBuf ) ).toString();
        logger.trc( "decrypted -> plainText: %d bytes = %s = %s", plainBuf.length, plainText, CodeUtils.encodeHex( plainBuf ) );

        return plainText;
    }

    protected byte[] aes_encrypt(final byte[] buf, final byte[] key) {
        return aes( true, buf, key );
    }

    protected byte[] aes_decrypt(final byte[] buf, final byte[] key) {
        return aes( false, buf, key );
    }

    protected byte[] aes(final boolean encrypt, final byte[] buf, final byte[] key) {
        int    blockByteSize = AES_BLOCKSIZE / Byte.SIZE;
        byte[] blockSizedKey = key;
        if (blockSizedKey.length != blockByteSize) {
            blockSizedKey = new byte[blockByteSize];
            System.arraycopy( key, 0, blockSizedKey, 0, blockByteSize );
        }

        // Encrypt data with key.
        try {
            Cipher                 cipher     = Cipher.getInstance( AES_TRANSFORMATION );
            AlgorithmParameterSpec parameters = new IvParameterSpec( new byte[blockByteSize] );
            cipher.init( encrypt? Cipher.ENCRYPT_MODE: Cipher.DECRYPT_MODE, new SecretKeySpec( blockSizedKey, "AES" ), parameters );

            return cipher.doFinal( buf );
        }
        catch (final NoSuchAlgorithmException e) {
            throw new IllegalStateException(
                    strf( "Cipher transformation: %s, is not valid or not supported by the provider.", AES_TRANSFORMATION ), e );
        }
        catch (final NoSuchPaddingException e) {
            throw new IllegalStateException(
                    strf( "Cipher transformation: %s, padding scheme is not supported by the provider.", AES_TRANSFORMATION ), e );
        }
        catch (final BadPaddingException e) {
            throw new IllegalArgumentException(
                    strf( "Message is incorrectly padded for cipher transformation: %s.", AES_TRANSFORMATION ), e );
        }
        catch (final IllegalBlockSizeException e) {
            throw new IllegalArgumentException(
                    strf( "Message size is invalid for cipher transformation: %s.", AES_TRANSFORMATION ), e );
        }
        catch (final InvalidKeyException e) {
            throw new IllegalArgumentException(
                    strf( "Key is inappropriate for cipher transformation: %s.", AES_TRANSFORMATION ), e );
        }
        catch (final InvalidAlgorithmParameterException e) {
            throw new IllegalStateException(
                    strf( "IV is inappropriate for cipher transformation: %s.", AES_TRANSFORMATION ), e );
        }
    }

    @Override
    public String siteResultFromDerive(final byte[] masterKey, final byte[] siteKey,
                                       final MPResultType resultType, @Nullable final String resultParam) {

        throw new UnsupportedOperationException( "TODO" );

        //        if (resultType == MPResultType.DeriveKey) {
        //            int resultParamInt = ConversionUtils.toIntegerNN( resultParam );
        //            if (resultParamInt == 0)
        //                resultParamInt = mpw_keySize_max();
        //            if ((resultParamInt < mpw_keySize_min()) || (resultParamInt > mpw_keySize_max()) || ((resultParamInt % 8) != 0))
        //                throw logger.bug( "Parameter is not a valid key size (should be 128 - 512): %s", resultParam );
        //            int keySize = resultParamInt / 8;
        //            logger.trc( "keySize: %d", keySize );
        //
        //            // Derive key
        //            byte[] resultKey = null; // TODO: mpw_kdf_blake2b()( keySize, siteKey, MPSiteKeySize, NULL, 0, 0, NULL );
        //            if (resultKey == null)
        //                throw logger.bug( "Could not derive result key." );
        //
        //            // Base64-encode
        //            String b64Key = Preconditions.checkNotNull( BaseEncoding.base64().encode( resultKey ) );
        //            logger.trc( "b64 encoded -> key: %s", b64Key );
        //
        //            return b64Key;
        //        } else
        //            throw logger.bug( "Unsupported derived password type: %s", resultType );
    }

    @Override
    public String siteState(final byte[] masterKey, final byte[] siteKey, final String siteName, final UnsignedInteger siteCounter,
                            final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                            final MPResultType resultType, final String resultParam) {

        // Encrypt
        byte[] cipherBuf = aes_encrypt( resultParam.getBytes( mpw_charset() ), masterKey );
        logger.trc( "cipherBuf: %d bytes = %s", cipherBuf.length, CodeUtils.encodeHex( cipherBuf ) );

        // Base64-encode
        String cipherText = Preconditions.checkNotNull( BaseEncoding.base64().encode( cipherBuf ) );
        logger.trc( "b64 encoded -> cipherText: %s", cipherText );

        return cipherText;
    }

    // Configuration

    @Override
    public Version version() {
        return MPAlgorithm.Version.V0;
    }

    @Override
    public UnsignedInteger mpw_default_counter() {
        return UnsignedInteger.ONE;
    }

    @Override
    public MPResultType mpw_default_result_type() {
        return MPResultType.GeneratedLong;
    }

    @Override
    public MPResultType mpw_default_login_type() {
        return MPResultType.GeneratedName;
    }

    @Override
    public MPResultType mpw_default_answer_type() {
        return MPResultType.GeneratedPhrase;
    }

    @Override
    public Charset mpw_charset() {
        return Charsets.UTF_8;
    }

    @Override
    public ByteOrder mpw_byteOrder() {
        return ByteOrder.BIG_ENDIAN;
    }

    @Override
    public MessageDigests mpw_hash() {
        return MessageDigests.SHA256;
    }

    @Override
    public MessageAuthenticationDigests mpw_digest() {
        return MessageAuthenticationDigests.HmacSHA256;
    }

    @Override
    @SuppressWarnings("MagicNumber")
    public int mpw_dkLen() {
        return 64;
    }

    @Override
    @SuppressWarnings("MagicNumber")
    public int mpw_keySize_min() {
        return 128;
    }

    @Override
    @SuppressWarnings("MagicNumber")
    public int mpw_keySize_max() {
        return 512;
    }

    @Override
    @SuppressWarnings("MagicNumber")
    public long mpw_otp_window() {
        return 5 * 60 /* s */;
    }

    @Override
    @SuppressWarnings("MagicNumber")
    public int scrypt_N() {
        return 32768;
    }

    @Override
    @SuppressWarnings("MagicNumber")
    public int scrypt_r() {
        return 8;
    }

    @Override
    @SuppressWarnings("MagicNumber")
    public int scrypt_p() {
        return 2;
    }

    // Utilities

    @Override
    public byte[] toBytes(final int number) {
        return ByteBuffer.allocate( Integer.SIZE / Byte.SIZE ).order( mpw_byteOrder() ).putInt( number ).array();
    }

    @Override
    public byte[] toBytes(final UnsignedInteger number) {
        return ByteBuffer.allocate( Integer.SIZE / Byte.SIZE ).order( mpw_byteOrder() ).putInt( number.intValue() ).array();
    }

    @Override
    public byte[] toBytes(final char[] characters) {
        ByteBuffer byteBuffer = mpw_charset().encode( CharBuffer.wrap( characters ) );

        byte[] bytes = new byte[byteBuffer.remaining()];
        byteBuffer.get( bytes );

        Arrays.fill( byteBuffer.array(), (byte) 0 );
        return bytes;
    }

    @Override
    public byte[] toID(final byte[] bytes) {
        return mpw_hash().of( bytes );
    }
}
