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

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import com.google.common.base.Charsets;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.MessageAuthenticationDigests;
import com.lyndir.lhunath.opal.system.MessageDigests;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.impl.*;
import java.nio.*;
import java.nio.charset.*;
import java.util.Arrays;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @see Version
 */
@SuppressWarnings({ "FieldMayBeStatic", "NewMethodNamingConvention", "MethodReturnAlwaysConstant" })
public interface MPAlgorithm {

    /**
     * Derive a master key that describes a user's identity.
     *
     * @param fullName       The name of the user whose identity is described by the key.
     * @param masterPassword The user's secret that authenticates his access to the identity.
     */
    @Nullable
    byte[] masterKey(String fullName, char[] masterPassword);

    /**
     * Derive a site key that describes a user's access to a specific entity.
     *
     * @param masterKey   The identity of the user trying to access the entity.
     * @param siteName    The name of the entity to access.
     * @param siteCounter The site key's generation.
     * @param keyPurpose  The action that the user aims to undertake with this key.
     * @param keyContext  An action-specific context within which to scope the key.
     */
    @Nullable
    byte[] siteKey(byte[] masterKey, String siteName, UnsignedInteger siteCounter,
                   MPKeyPurpose keyPurpose, @Nullable String keyContext);

    /**
     * Encode a templated result for a site key.
     *
     * @param resultType  The template to base the site key's encoding on.
     * @param resultParam A parameter that provides contextual data specific to the type template.
     */
    @Nullable
    String siteResult(byte[] masterKey, byte[] siteKey, String siteName, UnsignedInteger siteCounter,
                      MPKeyPurpose keyPurpose, @Nullable String keyContext,
                      MPResultType resultType, @Nullable String resultParam);

    /**
     * For {@link MPResultTypeClass#Stateful} {@code resultType}s, generate the {@code resultParam} to use with the
     * {@link #siteResult(byte[], byte[], String, UnsignedInteger, MPKeyPurpose, String, MPResultType, String)} call
     * in order to reconstruct this call's original {@code resultParam}.
     *
     * @param resultType  The template to base the site key's encoding on.
     * @param resultParam A parameter that provides contextual data specific to the type template.
     */
    @Nullable
    String siteState(byte[] masterKey, byte[] siteKey, String siteName, UnsignedInteger siteCounter,
                     MPKeyPurpose keyPurpose, @Nullable String keyContext,
                     MPResultType resultType, String resultParam);

    // Configuration

    /**
     * The linear version identifier of this algorithm's implementation.
     */
    @Nonnull
    Version version();

    /**
     * mpw: defaults: initial counter value.
     */
    @Nonnull
    UnsignedInteger mpw_default_counter();

    /**
     * mpw: defaults: password result type.
     */
    @Nonnull
    MPResultType mpw_default_result_type();

    /**
     * mpw: defaults: login result type.
     */
    @Nonnull
    MPResultType mpw_default_login_type();

    /**
     * mpw: defaults: answer result type.
     */
    @Nonnull
    MPResultType mpw_default_answer_type();

    /**
     * mpw: Input character encoding.
     */
    @Nonnull
    Charset mpw_charset();

    /**
     * mpw: Platform-agnostic byte order.
     */
    @Nonnull
    ByteOrder mpw_byteOrder();

    /**
     * mpw: Key ID hash.
     */
    @Nonnull
    MessageDigests mpw_hash();

    /**
     * mpw: Site digest.
     */
    @Nonnull
    MessageAuthenticationDigests mpw_digest();

    /**
     * mpw: Master key size (byte).
     */
    int mpw_dkLen();

    /**
     * mpw: Minimum size for derived keys (bit).
     */
    int mpw_keySize_min();

    /**
     * mpw: Maximum size for derived keys (bit).
     */
    int mpw_keySize_max();

    /**
     * mpw: validity for the time-based rolling counter (s).
     */
    long mpw_otp_window();

    /**
     * scrypt: CPU cost parameter.
     */
    int scrypt_N();

    /**
     * scrypt: Memory cost parameter.
     */
    int scrypt_r();

    /**
     * scrypt: Parallelization parameter.
     */
    int scrypt_p();

    // Utilities

    byte[] toBytes(final int number);

    byte[] toBytes(final UnsignedInteger number);

    byte[] toBytes(final char[] characters);

    byte[] toID(final byte[] bytes);

    /**
     * The algorithm iterations.
     */
    enum Version implements  MPAlgorithm {

        /**
         * bugs:
         * - does math with chars whose signedness was platform-dependent.
         * - miscounted the byte-length for multi-byte site names.
         * - miscounted the byte-length for multi-byte user names.
         */
        V0,

        /**
         * bugs:
         * - miscounted the byte-length for multi-byte site names.
         * - miscounted the byte-length for multi-byte user names.
         */
        V1,

        /**
         * bugs:
         * - miscounted the byte-length for multi-byte user names.
         */
        V2,

        /**
         * bugs:
         * - no known issues.
         */
        V3;

        public static final Version CURRENT = V3;

        @SuppressWarnings("HardcodedFileSeparator")
        private static final String AES_TRANSFORMATION = "AES/CBC/PKCS5Padding";
        private static final int    AES_BLOCKSIZE      = 128 /* bit */;

        static {
            Native.load( MPAlgorithm.class, "mpw" );
        }

        protected final Logger logger = Logger.get( getClass() );

        @JsonCreator
        public static Version fromInt(final int algorithmVersion) {

            return values()[algorithmVersion];
        }

        @JsonValue
        public int toInt() {

            return ordinal();
        }

        @Override
        public String toString() {

            return strf( "%d, %s", version().toInt(), getClass().getSimpleName() );
        }

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
                if (result.isError())
                    throw new IllegalStateException( result.toString() );
                result = encoder.flush( masterPasswordBuffer );
                if (result.isError())
                    throw new IllegalStateException( result.toString() );

                return _masterKey( fullName, masterPasswordBytes, version().toInt() );
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

        @Nonnull
        @Override
        public Version version() {
            return MPAlgorithm.Version.V0;
        }

        @Nonnull
        @Override
        public UnsignedInteger mpw_default_counter() {
            return UnsignedInteger.ONE;
        }

        @Nonnull
        @Override
        public MPResultType mpw_default_result_type() {
            return MPResultType.GeneratedLong;
        }

        @Nonnull
        @Override
        public MPResultType mpw_default_login_type() {
            return MPResultType.GeneratedName;
        }

        @Nonnull
        @Override
        public MPResultType mpw_default_answer_type() {
            return MPResultType.GeneratedPhrase;
        }

        @Nonnull
        @Override
        public Charset mpw_charset() {
            return Charsets.UTF_8;
        }

        @Nonnull
        @Override
        public ByteOrder mpw_byteOrder() {
            return ByteOrder.BIG_ENDIAN;
        }

        @Nonnull
        @Override
        public MessageDigests mpw_hash() {
            return MessageDigests.SHA256;
        }

        @Nonnull
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

        @Nonnull
        public byte[] toBytes(final int number) {
            return ByteBuffer.allocate( Integer.SIZE / Byte.SIZE ).order( mpw_byteOrder() ).putInt( number ).array();
        }

        @Nonnull
        public byte[] toBytes(final UnsignedInteger number) {
            return ByteBuffer.allocate( Integer.SIZE / Byte.SIZE ).order( mpw_byteOrder() ).putInt( number.intValue() ).array();
        }

        @Nonnull
        public byte[] toBytes(final char[] characters) {
            ByteBuffer byteBuffer = mpw_charset().encode( CharBuffer.wrap( characters ) );

            byte[] bytes = new byte[byteBuffer.remaining()];
            byteBuffer.get( bytes );

            Arrays.fill( byteBuffer.array(), (byte) 0 );
            return bytes;
        }

        @Nonnull
        public byte[] toID(final byte[] bytes) {
            return mpw_hash().of( bytes );
        }
    }
}
