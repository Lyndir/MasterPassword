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

import com.google.common.base.Preconditions;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.Arrays;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-08-30
 */
public abstract class MasterKey {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger  logger               = Logger.get( MasterKey.class );
    private static       boolean allowNativeByDefault = true;

    @Nonnull
    private final String fullName;
    private boolean allowNative = allowNativeByDefault;

    @Nullable
    private byte[] masterKey;

    @SuppressWarnings("MethodCanBeVariableArityMethod")
    public static MasterKey create(final String fullName, final char[] masterPassword) {

        return create( Version.CURRENT, fullName, masterPassword );
    }

    @Nonnull
    @SuppressWarnings("MethodCanBeVariableArityMethod")
    public static MasterKey create(final Version version, final String fullName, final char[] masterPassword) {

        switch (version) {
            case V0:
                return new MasterKeyV0( fullName ).revalidate( masterPassword );
            case V1:
                return new MasterKeyV1( fullName ).revalidate( masterPassword );
            case V2:
                return new MasterKeyV2( fullName ).revalidate( masterPassword );
            case V3:
                return new MasterKeyV3( fullName ).revalidate( masterPassword );
        }

        throw new UnsupportedOperationException( strf( "Unsupported version: %s", version ) );
    }

    public static boolean isAllowNativeByDefault() {
        return allowNativeByDefault;
    }

    /**
     * Native libraries are useful for speeding up the performance of cryptographical functions.
     * Sometimes, however, we may prefer to use Java-only code.
     * For instance, for auditability / trust or because the native code doesn't work on our CPU/platform.
     * <p/>
     * This setter affects the default setting for any newly created {@link MasterKey}s.
     *
     * @param allowNative false to disallow the use of native libraries.
     */
    public static void setAllowNativeByDefault(final boolean allowNative) {
        allowNativeByDefault = allowNative;
    }

    protected MasterKey(final String fullName) {
        Preconditions.checkArgument( !fullName.isEmpty() );

        this.fullName = fullName;
        logger.trc( "fullName: %s", fullName );
    }

    /**
     * Derive the master key for a user based on their name and master password.
     *
     * @param masterPassword The user's master password.
     */
    @Nullable
    @SuppressWarnings("MethodCanBeVariableArityMethod")
    protected abstract byte[] deriveKey(char[] masterPassword);

    /**
     * Derive the site key for a user's site from the given master key and site parameters.
     *
     * @param siteName    A site identifier.
     * @param siteCounter The result identifier.
     * @param keyPurpose  The intended purpose for this site key.
     * @param keyContext  A site-scoped key modifier.
     */
    protected abstract byte[] siteKey(String siteName, UnsignedInteger siteCounter, MPKeyPurpose keyPurpose,
                                      @Nullable String keyContext);

    /**
     * Generate a site result token.
     *
     * @param siteName    A site identifier.
     * @param siteCounter The result identifier.
     * @param keyPurpose  The intended purpose for this site result.
     * @param keyContext  A site-scoped result modifier.
     * @param resultType  The type of result to generate.
     * @param resultParam A parameter for the resultType.  For stateful result types, the output of
     *                    {@link #siteState(String, UnsignedInteger, MPKeyPurpose, String, MPResultType, String)}.
     */
    public abstract String siteResult(String siteName, UnsignedInteger siteCounter, MPKeyPurpose keyPurpose,
                                      @Nullable String keyContext, MPResultType resultType, @Nullable String resultParam);

    protected abstract String sitePasswordFromTemplate(byte[] siteKey, MPResultType resultType, @Nullable String resultParam);

    protected abstract String sitePasswordFromCrypt(byte[] siteKey, MPResultType resultType, @Nullable String resultParam);

    protected abstract String sitePasswordFromDerive(byte[] siteKey, MPResultType resultType, @Nullable String resultParam);

    /**
     * Encrypt a stateful site token for persistence.
     *
     * @param siteName    A site identifier.
     * @param siteCounter The result identifier.
     * @param keyPurpose  The intended purpose for the site token.
     * @param keyContext  A site-scoped key modifier.
     * @param resultType  The type of result token to encrypt.
     * @param resultParam The result token desired from
     *                    {@link #siteResult(String, UnsignedInteger, MPKeyPurpose, String, MPResultType, String)}.
     */
    public abstract String siteState(String siteName, UnsignedInteger siteCounter, MPKeyPurpose keyPurpose,
                                     @Nullable String keyContext, MPResultType resultType, @Nullable String resultParam);

    public abstract Version getAlgorithmVersion();

    @Nonnull
    public String getFullName() {

        return fullName;
    }

    public boolean isAllowNative() {
        return allowNative;
    }

    public MasterKey setAllowNative(final boolean allowNative) {
        this.allowNative = allowNative;
        return this;
    }

    @Nonnull
    protected byte[] getKey() {

        Preconditions.checkState( isValid() );
        return Preconditions.checkNotNull( masterKey );
    }

    public byte[] getKeyID() {

        return idForBytes( getKey() );
    }

    public boolean isValid() {
        return masterKey != null;
    }

    public void invalidate() {

        if (masterKey != null) {
            Arrays.fill( masterKey, (byte) 0 );
            masterKey = null;
        }
    }

    @SuppressWarnings("MethodCanBeVariableArityMethod")
    public MasterKey revalidate(final char[] masterPassword) {
        invalidate();

        logger.trc( "masterPassword: %s", new String( masterPassword ) );

        long start = System.currentTimeMillis();
        masterKey = deriveKey( masterPassword );

        if (masterKey == null)
            logger.dbg( "masterKey calculation failed after %.2fs.", (double) (System.currentTimeMillis() - start) / MPConstant.MS_PER_S );
        else
            logger.trc( "masterKey ID: %s (derived in %.2fs)", CodeUtils.encodeHex( idForBytes( masterKey ) ),
                        (double) (System.currentTimeMillis() - start) / MPConstant.MS_PER_S );

        return this;
    }

    protected abstract byte[] bytesForInt(int number);

    protected abstract byte[] bytesForInt(UnsignedInteger number);

    protected abstract byte[] idForBytes(byte[] bytes);

    public enum Version {
        /**
         * bugs:
         * - does math with chars whose signedness was platform-dependent.
         * - miscounted the byte-length for multi-byte site names.
         * - miscounted the byte-length for multi-byte full names.
         */
        V0,
        /**
         * bugs:
         * - miscounted the byte-length for multi-byte site names.
         * - miscounted the byte-length for multi-byte full names.
         */
        V1,
        /**
         * bugs:
         * - miscounted the byte-length for multi-byte full names.
         */
        V2,
        /**
         * bugs:
         * - no known issues.
         */
        V3;

        public static final Version CURRENT = V3;

        public static Version fromInt(final int algorithmVersion) {

            return values()[algorithmVersion];
        }

        public int toInt() {

            return ordinal();
        }
    }
}
