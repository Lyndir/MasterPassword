package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.lyndir.masterpassword.MasterKey;
import com.lyndir.masterpassword.model.MPUser;
import java.security.KeyException;
import java.util.Objects;
import javax.annotation.Nonnull;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class User {

    private MasterKey key;

    public abstract String getFullName();

    protected abstract String getMasterPassword();

    public int getAvatar() {
        return 0;
    }

    public boolean hasKey() {
        String masterPassword = getMasterPassword();
        return key != null || (masterPassword != null && !masterPassword.isEmpty());
    }

    @Nonnull
    public MasterKey getKey() throws MasterKeyException {
        if (key == null) {
            String masterPassword = getMasterPassword();
            if (masterPassword == null || masterPassword.isEmpty()) {
                reset();
                throw new MasterKeyException( strf( "Master password unknown for user: %s", getFullName() ) );
            }

            key = new MasterKey( getFullName(), masterPassword );
        }

        return key;
    }

    public void reset() {
        key = null;
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
