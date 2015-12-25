package com.lyndir.masterpassword;

import com.google.common.base.Preconditions;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.Arrays;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.jetbrains.annotations.NotNull;


/**
 * @author lhunath, 2014-08-30
 */
public abstract class MasterKey {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MasterKey.class );

    @Nonnull
    private final String fullName;

    @Nullable
    private byte[] masterKey;

    public static MasterKey create(final String fullName, final char[] masterPassword) {

        return create( Version.CURRENT, fullName, masterPassword );
    }

    @Nonnull
    public static MasterKey create(Version version, final String fullName, final char[] masterPassword) {

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

        throw new UnsupportedOperationException( "Unsupported version: " + version );
    }

    protected MasterKey(@NotNull final String fullName) {

        this.fullName = fullName;
        logger.trc( "fullName: %s", fullName );
    }

    @Nullable
    protected abstract byte[] deriveKey(final char[] masterPassword);

    public abstract Version getAlgorithmVersion();

    @NotNull
    public String getFullName() {

        return fullName;
    }

    @Nonnull
    protected byte[] getKey() {

        Preconditions.checkState( isValid() );
        return Preconditions.checkNotNull( masterKey );
    }

    public byte[] getKeyID() {

        return idForBytes( getKey() );
    }

    public abstract String encode(@Nonnull final String siteName, final MPSiteType siteType, @Nonnull final UnsignedInteger siteCounter,
                                  final MPSiteVariant siteVariant, @Nullable final String siteContext);

    public boolean isValid() {
        return masterKey != null;
    }

    public void invalidate() {

        if (masterKey != null) {
            Arrays.fill( masterKey, (byte) 0 );
            masterKey = null;
        }
    }

    public MasterKey revalidate(final char[] masterPassword) {
        invalidate();

        logger.trc( "masterPassword: %s", new String( masterPassword ) );

        long start = System.currentTimeMillis();
        masterKey = deriveKey( masterPassword );

        if (masterKey == null)
            logger.dbg( "masterKey calculation failed after %.2fs.", (System.currentTimeMillis() - start) / 1000D );
        else
            logger.trc( "masterKey ID: %s (derived in %.2fs)", CodeUtils.encodeHex( idForBytes( masterKey ) ),
                        (System.currentTimeMillis() - start) / 1000D );

        return this;
    }

    protected abstract byte[] bytesForInt(final int number);

    protected abstract byte[] bytesForInt(@Nonnull final UnsignedInteger number);

    protected abstract byte[] idForBytes(final byte[] bytes);

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

            throw new UnsupportedOperationException( "Unsupported version: " + this );
        }
    }
}
