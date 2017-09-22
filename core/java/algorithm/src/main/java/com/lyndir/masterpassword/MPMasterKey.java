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

import static com.lyndir.masterpassword.MPUtils.idForBytes;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.Arrays;
import java.util.EnumMap;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-08-30
 */
public class MPMasterKey {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPMasterKey.class );

    private final EnumMap<Version, byte[]> keyByVersion = new EnumMap<>( Version.class );
    private final String fullName;
    private final char[] masterPassword;

    private boolean invalidated;

    /**
     * @param masterPassword The characters of the user's master password.  Note: this array is held by reference and its contents
     *                       invalidated on {@link #invalidate()}.
     */
    @SuppressWarnings("AssignmentToCollectionOrArrayFieldFromParameter")
    public MPMasterKey(final String fullName, final char[] masterPassword) {

        this.fullName = fullName;
        this.masterPassword = masterPassword;
    }

    /**
     * Generate a site result token.
     *
     * @param siteName    A site identifier.
     * @param siteCounter The result identifier.
     * @param keyPurpose  The intended purpose for this site result.
     * @param keyContext  A site-scoped result modifier.
     * @param resultType  The type of result to generate.
     * @param resultParam A parameter for the resultType.  For stateful result types, the output of
     *                    {@link #siteState(String, UnsignedInteger, MPKeyPurpose, String, MPResultType, String, Version)}.
     *
     * @throws MPInvalidatedException {@link #invalidate()} has been called on this object.
     */
    public String siteResult(final String siteName, final UnsignedInteger siteCounter, final MPKeyPurpose keyPurpose,
                             @Nullable final String keyContext, final MPResultType resultType, @Nullable final String resultParam,
                             final Version algorithmVersion)
            throws MPInvalidatedException {
        return algorithmVersion.getAlgorithm().siteResult(
                getKey( algorithmVersion ), siteName, siteCounter, keyPurpose, keyContext, resultType, resultParam );
    }

    /**
     * Encrypt a stateful site token for persistence.
     *
     * @param siteName    A site identifier.
     * @param siteCounter The result identifier.
     * @param keyPurpose  The intended purpose for the site token.
     * @param keyContext  A site-scoped key modifier.
     * @param resultType  The type of result token to encrypt.
     * @param resultParam The result token desired from
     *                    {@link #siteResult(String, UnsignedInteger, MPKeyPurpose, String, MPResultType, String, Version)}.
     *
     * @throws MPInvalidatedException {@link #invalidate()} has been called on this object.
     */
    public String siteState(final String siteName, final UnsignedInteger siteCounter, final MPKeyPurpose keyPurpose,
                            @Nullable final String keyContext, final MPResultType resultType, @Nullable final String resultParam,
                            final Version algorithmVersion)
            throws MPInvalidatedException {
        return algorithmVersion.getAlgorithm().siteState(
                getKey( algorithmVersion ), siteName, siteCounter, keyPurpose, keyContext, resultType, resultParam );
    }

    @Nonnull
    public String getFullName() {

        return fullName;
    }

    /**
     * Calculate an identifier for the master key.
     *
     * @throws MPInvalidatedException {@link #invalidate()} has been called on this object.
     */
    public byte[] getKeyID(final Version algorithmVersion)
            throws MPInvalidatedException {

        return idForBytes( getKey( algorithmVersion ) );
    }

    /**
     * Wipe this key's secrets from memory, making the object permanently unusable.
     */
    public void invalidate() {

        invalidated = true;
        for (final byte[] key : keyByVersion.values())
            Arrays.fill( key, (byte) 0 );
        Arrays.fill( masterPassword, (char) 0 );
    }

    private byte[] getKey(final Version algorithmVersion)
            throws MPInvalidatedException {
        if (invalidated)
            throw new MPInvalidatedException();

        byte[] key = keyByVersion.get( algorithmVersion );
        if (key == null)
            keyByVersion.put( algorithmVersion, key = algorithmVersion.getAlgorithm().deriveKey( fullName, masterPassword ) );

        return key;
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

        public static Version fromInt(final int algorithmVersion) {

            return values()[algorithmVersion];
        }

        public int toInt() {

            return ordinal();
        }
    }
}
