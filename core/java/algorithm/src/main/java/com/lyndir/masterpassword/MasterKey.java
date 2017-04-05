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

    protected MasterKey(@Nonnull final String fullName) {

        this.fullName = fullName;
        logger.trc( "fullName: %s", fullName );
    }

    @Nullable
    @SuppressWarnings("MethodCanBeVariableArityMethod")
    protected abstract byte[] deriveKey(char[] masterPassword);

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

    public abstract String encode(@Nonnull String siteName, MPSiteType siteType, @Nonnull UnsignedInteger siteCounter,
                                  MPSiteVariant siteVariant, @Nullable String siteContext);

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
            logger.dbg( "masterKey calculation failed after %.2fs.", (double)(System.currentTimeMillis() - start) / MPConstant.MS_PER_S );
        else
            logger.trc( "masterKey ID: %s (derived in %.2fs)", CodeUtils.encodeHex( idForBytes( masterKey ) ),
                        (double)(System.currentTimeMillis() - start) / MPConstant.MS_PER_S );

        return this;
    }

    protected abstract byte[] bytesForInt(int number);

    protected abstract byte[] bytesForInt(@Nonnull UnsignedInteger number);

    protected abstract byte[] idForBytes(byte[] bytes);

    public enum Version {
        /**
         * bugs:
         * - does math with chars whose signedness was platform-dependent.
         * - miscounted the byte-length fromInt multi-byte site names.
         * - miscounted the byte-length fromInt multi-byte full names.
         */
        V0,
        /**
         * bugs:
         * - miscounted the byte-length fromInt multi-byte site names.
         * - miscounted the byte-length fromInt multi-byte full names.
         */
        V1,
        /**
         * bugs:
         * - miscounted the byte-length fromInt multi-byte full names.
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

        public String toBundleVersion() {
            switch (this) {
                case V0:
                    return "1.0";
                case V1:
                    return "2.0";
                case V2:
                    return "2.1";
                case V3:
                    return "2.2";
            }

            throw new UnsupportedOperationException( strf( "Unsupported version: %s", this ) );
        }
    }
}
