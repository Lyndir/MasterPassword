package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.lyndir.masterpassword.MasterKey;
import javax.annotation.Nonnull;
import org.jetbrains.annotations.NotNull;


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

    @NotNull
    @Nonnull
    public MasterKey getKey() {
        if (key == null) {
            if (!hasKey())
                throw new IllegalStateException( strf( "Master password unknown for user: %s", getFullName() ) );
            key = new MasterKey( getFullName(), getMasterPassword() );
        }

        return key;
    }

    @Override
    public int hashCode() {
        return getFullName().hashCode();
    }

    @Override
    public String toString() {
        return getFullName();
    }

    public abstract Iterable<Site> findSitesByName(final String siteName);

    public abstract void addSite(final Site site);
}
