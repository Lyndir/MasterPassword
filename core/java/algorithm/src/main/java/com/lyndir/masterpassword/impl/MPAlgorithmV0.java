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

import com.google.common.base.Charsets;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.MessageAuthenticationDigests;
import com.lyndir.lhunath.opal.system.MessageDigests;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.*;
import java.nio.*;
import java.nio.charset.*;
import java.util.Arrays;
import javax.annotation.Nullable;


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
        Native.load( MPAlgorithmV0.class, "masterpassword-core" );
    }

    public final Version version = MPAlgorithm.Version.V0;

    protected final Logger logger = Logger.get( getClass() );

    @Nullable
    @Override
    public byte[] masterKey(final String fullName, final char[] masterPassword) {

        // Create a memory-safe NUL-terminated UTF-8 C-string byte array variant of masterPassword.
        CharsetEncoder encoder             = mpw_charset().newEncoder();
        byte[]         masterPasswordBytes = new byte[(int) (masterPassword.length * (double) encoder.maxBytesPerChar()) + 1];
        try {
            Arrays.fill( masterPasswordBytes, (byte) 0 );
            ByteBuffer masterPasswordBuffer = ByteBuffer.wrap( masterPasswordBytes );

            CoderResult result = encoder.encode( CharBuffer.wrap( masterPassword ), masterPasswordBuffer, true );
            if (!result.isUnderflow())
                result.throwException();
            result = encoder.flush( masterPasswordBuffer );
            if (!result.isUnderflow())
                result.throwException();

            return _masterKey( fullName, masterPasswordBytes, version().toInt() );
        }
        catch (final CharacterCodingException e) {
            throw new IllegalStateException( e );
        }
        finally {
            Arrays.fill( masterPasswordBytes, (byte) 0 );
        }
    }

    @Nullable
    protected native byte[] _masterKey(final String fullName, final byte[] masterPassword, final int algorithmVersion);

    @Nullable
    @Override
    public byte[] siteKey(final byte[] masterKey, final String siteName, final UnsignedInteger siteCounter,
                          final MPKeyPurpose keyPurpose, @Nullable final String keyContext) {

        return _siteKey( masterKey, siteName, siteCounter.longValue(), keyPurpose.toInt(), keyContext, version().toInt() );
    }

    @Nullable
    protected native byte[] _siteKey(final byte[] masterKey, final String siteName, final long siteCounter,
                                     final int keyPurpose, @Nullable final String keyContext, final int version);

    @Nullable
    @Override
    public String siteResult(final byte[] masterKey, final byte[] siteKey, final String siteName, final UnsignedInteger siteCounter,
                             final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                             final MPResultType resultType, @Nullable final String resultParam) {

        return _siteResult( masterKey, siteKey, siteName, siteCounter.longValue(),
                            keyPurpose.toInt(), keyContext, resultType.getType(), resultParam, version().toInt() );
    }

    @Nullable
    protected native String _siteResult(final byte[] masterKey, final byte[] siteKey, final String siteName, final long siteCounter,
                                        final int keyPurpose, @Nullable final String keyContext,
                                        final int resultType, @Nullable final String resultParam, final int algorithmVersion);

    @Nullable
    @Override
    public String siteState(final byte[] masterKey, final byte[] siteKey, final String siteName, final UnsignedInteger siteCounter,
                            final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                            final MPResultType resultType, final String resultParam) {

        return _siteState( masterKey, siteKey, siteName, siteCounter.longValue(),
                           keyPurpose.toInt(), keyContext, resultType.getType(), resultParam, version().toInt() );
    }

    @Nullable
    protected native String _siteState(final byte[] masterKey, final byte[] siteKey, final String siteName, final long siteCounter,
                                       final int keyPurpose, @Nullable final String keyContext,
                                       final int resultType, final String resultParam, final int algorithmVersion);

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
