package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.Maps;
import com.lyndir.masterpassword.MasterKey;
import com.lyndir.masterpassword.model.IncorrectMasterPasswordException;
import java.util.EnumMap;
import java.util.Objects;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class User {

    @Nonnull
    private static final EnumMap<MasterKey.Version, MasterKey> keyByVersion = Maps.newEnumMap( MasterKey.Version.class  );

    public abstract String getFullName();

    @Nullable
    protected abstract char[] getMasterPassword();

    public abstract void authenticate(final char[] masterPassword)
            throws IncorrectMasterPasswordException;

    public int getAvatar() {
        return 0;
    }

    public boolean isKeyAvailable() {
        return getMasterPassword() != null;
    }

    @Nonnull
    public MasterKey getKey(MasterKey.Version algorithmVersion) {
        char[] masterPassword = getMasterPassword();

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
