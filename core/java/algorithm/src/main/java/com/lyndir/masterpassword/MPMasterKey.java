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

import com.google.common.base.Preconditions;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.CodeUtils;
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

    private final EnumMap<MPAlgorithm.Version, byte[]> keyByVersion = new EnumMap<>( MPAlgorithm.Version.class );
    private final String                               fullName;
    private final char[]                               masterPassword;

    private boolean invalidated;

    /**
     * @param masterPassword The characters of the user's master password.
     *                       Note: this array is held by reference and its contents invalidated on {@link #invalidate()}.
     */
    @SuppressWarnings("AssignmentToCollectionOrArrayFieldFromParameter")
    public MPMasterKey(final String fullName, final char[] masterPassword) {

        this.fullName = fullName;
        this.masterPassword = masterPassword;
    }

    @Nonnull
    public String getFullName() {

        return fullName;
    }

    /**
     * Calculate an identifier for the master key.
     *
     * @throws MPKeyUnavailableException {@link #invalidate()} has been called on this object.
     */
    public byte[] getKeyID(final MPAlgorithm algorithm)
            throws MPKeyUnavailableException {

        return algorithm.toID( masterKey( algorithm ) );
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

    private byte[] masterKey(final MPAlgorithm algorithm)
            throws MPKeyUnavailableException {
        Preconditions.checkArgument( masterPassword.length > 0 );

        if (invalidated)
            throw new MPKeyUnavailableException();

        byte[] key = keyByVersion.get( algorithm.version() );
        if (key == null) {
            logger.trc( "-- mpw_masterKey (algorithm: %s)", algorithm );
            logger.trc( "fullName: %s", fullName );
            logger.trc( "masterPassword.id: %s", CodeUtils.encodeHex(
                    algorithm.toID( algorithm.toBytes( masterPassword ) ) ) );

            keyByVersion.put( algorithm.version(), key = algorithm.masterKey( fullName, masterPassword ) );
        }

        return key;
    }

    private byte[] siteKey(final String siteName, final MPAlgorithm algorithm, final UnsignedInteger siteCounter,
                           final MPKeyPurpose keyPurpose, @Nullable final String keyContext)
            throws MPKeyUnavailableException {
        Preconditions.checkArgument( !siteName.isEmpty() );

        byte[] masterKey = masterKey( algorithm );

        logger.trc( "-- mpw_siteKey (algorithm: %s)", algorithm );
        logger.trc( "siteName: %s", siteName );
        logger.trc( "siteCounter: %s", siteCounter );
        logger.trc( "keyPurpose: %d (%s)", keyPurpose.toInt(), keyPurpose.getShortName() );
        logger.trc( "keyContext: %s", keyContext );

        return algorithm.siteKey( masterKey, siteName, siteCounter, keyPurpose, keyContext );
    }

    /**
     * Generate a token for use with site.
     *
     * @param siteName    The site's identifier.
     * @param siteCounter The result's generation.
     * @param keyPurpose  The intended purpose for the site token.
     * @param keyContext  The purpose-specific context for this token.
     * @param resultType  The type of token we're deriving.
     * @param resultParam Type-specific contextual data for the derivation.
     *                    In the case of {@link MPResultTypeClass#Stateful} types, the result of
     *                    {@link #siteState(String, MPAlgorithm, UnsignedInteger, MPKeyPurpose, String, MPResultType, String)}.
     *
     * @throws MPKeyUnavailableException {@link #invalidate()} has been called on this object.
     */
    public String siteResult(final String siteName, final MPAlgorithm algorithm, final UnsignedInteger siteCounter,
                             final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                             final MPResultType resultType, @Nullable final String resultParam)
            throws MPKeyUnavailableException {

        byte[] masterKey = masterKey( algorithm );
        byte[] siteKey   = siteKey( siteName, algorithm, siteCounter, keyPurpose, keyContext );

        logger.trc( "-- mpw_siteResult (algorithm: %s)", algorithm );
        logger.trc( "resultType: %d (%s)", resultType.getType(), resultType.getShortName() );
        logger.trc( "resultParam: %s", resultParam );

        return algorithm.siteResult(
                masterKey, siteKey, siteName, siteCounter, keyPurpose, keyContext, resultType, resultParam );
    }

    /**
     * Encrypt a stateful site token for persistence.
     *
     * @param siteName    The site's identifier.
     * @param siteCounter The result's generation.
     * @param keyPurpose  The intended purpose for the site token.
     * @param keyContext  The purpose-specific context for this token.
     * @param resultType  The type of token we're deriving.
     * @param resultParam The original token that this method's state should reconstruct when passed into
     *                    {@link #siteResult(String, MPAlgorithm, UnsignedInteger, MPKeyPurpose, String, MPResultType, String)}.
     *
     * @throws MPKeyUnavailableException {@link #invalidate()} has been called on this object.
     */
    public String siteState(final String siteName, final MPAlgorithm algorithm, final UnsignedInteger siteCounter,
                            final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                            final MPResultType resultType, @Nullable final String resultParam)
            throws MPKeyUnavailableException {

        Preconditions.checkNotNull( resultParam );
        Preconditions.checkArgument( !resultParam.isEmpty() );

        byte[] masterKey = masterKey( algorithm );
        byte[] siteKey   = siteKey( siteName, algorithm, siteCounter, keyPurpose, keyContext );

        logger.trc( "-- mpw_siteState (algorithm: %s)", algorithm );
        logger.trc( "resultType: %d (%s)", resultType.getType(), resultType.getShortName() );
        logger.trc( "resultParam: %d bytes = %s", resultParam.getBytes( algorithm.mpw_charset() ).length, resultParam );

        return algorithm.siteState(
                masterKey, siteKey, siteName, siteCounter, keyPurpose, keyContext, resultType, resultParam );
    }
}
