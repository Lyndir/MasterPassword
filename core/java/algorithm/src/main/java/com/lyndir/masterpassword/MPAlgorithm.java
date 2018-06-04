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
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.MessageAuthenticationDigests;
import com.lyndir.lhunath.opal.system.MessageDigests;
import com.lyndir.masterpassword.impl.*;
import java.nio.ByteOrder;
import java.nio.charset.Charset;
import javax.annotation.Nullable;


/**
 * @see Version
 */
@SuppressWarnings({ "FieldMayBeStatic", "NewMethodNamingConvention", "MethodReturnAlwaysConstant" })
public abstract class MPAlgorithm {

    /**
     * Derive a master key that describes a user's identity.
     *
     * @param fullName       The name of the user whose identity is described by the key.
     * @param masterPassword The user's secret that authenticates his access to the identity.
     */
    @Nullable
    public abstract byte[] masterKey(String fullName, char[] masterPassword);

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
    public abstract byte[] siteKey(byte[] masterKey, String siteName, UnsignedInteger siteCounter,
                                   MPKeyPurpose keyPurpose, @Nullable String keyContext);

    /**
     * Encode a templated result for a site key.
     *
     * @param resultType  The template to base the site key's encoding on.
     * @param resultParam A parameter that provides contextual data specific to the type template.
     */
    @Nullable
    public abstract String siteResult(byte[] masterKey, byte[] siteKey, String siteName, UnsignedInteger siteCounter,
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
    public abstract String siteState(byte[] masterKey, byte[] siteKey, String siteName, UnsignedInteger siteCounter,
                                     MPKeyPurpose keyPurpose, @Nullable String keyContext,
                                     MPResultType resultType, String resultParam);

    // Configuration

    /**
     * The linear version identifier of this algorithm's implementation.
     */
    public abstract Version version();

    /**
     * mpw: defaults: initial counter value.
     */
    public abstract UnsignedInteger mpw_default_counter();

    /**
     * mpw: defaults: password result type.
     */
    public abstract MPResultType mpw_default_result_type();

    /**
     * mpw: defaults: login result type.
     */
    public abstract MPResultType mpw_default_login_type();

    /**
     * mpw: defaults: answer result type.
     */
    public abstract MPResultType mpw_default_answer_type();

    /**
     * mpw: Input character encoding.
     */
    public abstract Charset mpw_charset();

    /**
     * mpw: Platform-agnostic byte order.
     */
    public abstract ByteOrder mpw_byteOrder();

    /**
     * mpw: Key ID hash.
     */
    public abstract MessageDigests mpw_hash();

    /**
     * mpw: Site digest.
     */
    public abstract MessageAuthenticationDigests mpw_digest();

    /**
     * mpw: Master key size (byte).
     */
    public abstract int mpw_dkLen();

    /**
     * mpw: Minimum size for derived keys (bit).
     */
    public abstract int mpw_keySize_min();

    /**
     * mpw: Maximum size for derived keys (bit).
     */
    public abstract int mpw_keySize_max();

    /**
     * mpw: validity for the time-based rolling counter (s).
     */
    public abstract long mpw_otp_window();

    /**
     * scrypt: CPU cost parameter.
     */
    public abstract int scrypt_N();

    /**
     * scrypt: Memory cost parameter.
     */
    public abstract int scrypt_r();

    /**
     * scrypt: Parallelization parameter.
     */
    public abstract int scrypt_p();

    // Utilities

    protected abstract byte[] toBytes(int number);

    protected abstract byte[] toBytes(UnsignedInteger number);

    protected abstract byte[] toBytes(char[] characters);

    protected abstract byte[] toID(byte[] bytes);

    @Override
    public String toString() {
        
        return strf( "%d, %s", version().toInt(), getClass().getSimpleName() );
    }

    /**
     * The algorithm iterations.
     */
    public enum Version {

        /**
         * bugs:
         * - does math with chars whose signedness was platform-dependent.
         * - miscounted the byte-length for multi-byte site names.
         * - miscounted the byte-length for multi-byte user names.
         */
        V0( new MPAlgorithmV0() ),

        /**
         * bugs:
         * - miscounted the byte-length for multi-byte site names.
         * - miscounted the byte-length for multi-byte user names.
         */
        V1( new MPAlgorithmV1() ),

        /**
         * bugs:
         * - miscounted the byte-length for multi-byte user names.
         */
        V2( new MPAlgorithmV2() ),

        /**
         * bugs:
         * - no known issues.
         */
        V3( new MPAlgorithmV3() );

        public static final Version CURRENT = V3;

        private final MPAlgorithm algorithm;

        Version(final MPAlgorithm algorithm) {
            this.algorithm = algorithm;
        }

        public MPAlgorithm getAlgorithm() {
            return algorithm;
        }

        @JsonCreator
        public static Version fromInt(final int algorithmVersion) {

            return values()[algorithmVersion];
        }

        @JsonValue
        public int toInt() {

            return ordinal();
        }
    }
}
