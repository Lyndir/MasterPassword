package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.lyndir.masterpassword.MasterKey;
import javax.annotation.Nonnull;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class User {

    private MasterKey key;

    public abstract String getFullName();

    protected abstract String getMasterPassword();

    public boolean hasKey() {
        String masterPassword = getMasterPassword();
        return key != null || (masterPassword != null && !masterPassword.isEmpty());
    }

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
}
