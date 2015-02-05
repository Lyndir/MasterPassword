package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.Maps;
import com.lyndir.masterpassword.MasterKey;
import java.util.EnumMap;
import java.util.Objects;
import javax.annotation.Nonnull;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class User {

    @Nonnull
    private static final EnumMap<MasterKey.Version, MasterKey> keyByVersion = Maps.newEnumMap( MasterKey.Version.class  );

    public abstract String getFullName();

    protected abstract String getMasterPassword();

    public abstract MasterKey.Version getAlgorithmVersion();

    public abstract void setAlgorithmVersion(final MasterKey.Version algorithmVersion);

    public int getAvatar() {
        return 0;
    }

    public boolean isKeyAvailable() {
        String masterPassword = getMasterPassword();
        return masterPassword != null && !masterPassword.isEmpty();
    }

    @Nonnull
    public MasterKey getKey() throws MasterKeyException {
        return getKey( getAlgorithmVersion() );
    }

    @Nonnull
    public MasterKey getKey(MasterKey.Version algorithmVersion) throws MasterKeyException {
        String masterPassword = getMasterPassword();
        if (masterPassword == null || masterPassword.isEmpty()) {
            reset();
            throw new MasterKeyException( strf( "Master password unknown for user: %s", getFullName() ) );
        }

        MasterKey key = keyByVersion.get( algorithmVersion );
        if (key == null)
            keyByVersion.put( algorithmVersion, key = MasterKey.create( algorithmVersion, getFullName(), masterPassword ) );
        if (!key.isValid())
            key.revalidate( masterPassword );

        return key;
    }

    public void reset() {
        for (MasterKey key : keyByVersion.values())
            key.invalidate();
    }

    public abstract Iterable<Site> findSitesByName(final String siteName);

    public abstract void addSite(final Site site);

    @Override
    public boolean equals(final Object obj) {
        return this == obj || obj instanceof User && Objects.equals( getFullName(), ((User) obj).getFullName() );
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( getFullName() );
    }

    @Override
    public String toString() {
        return getFullName();
    }
}
