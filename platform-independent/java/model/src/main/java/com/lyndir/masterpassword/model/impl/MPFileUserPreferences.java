package com.lyndir.masterpassword.model.impl;

import com.lyndir.masterpassword.MPResultType;
import java.util.Objects;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-10-13
 */
public class MPFileUserPreferences extends MPBasicUserPreferences<MPFileUser> {

    public MPFileUserPreferences(final MPFileUser user, @Nullable final MPResultType defaultType, final boolean hidePasswords) {
        super( user );

        setDefaultType( defaultType );
        setHidePasswords( hidePasswords );
    }

    @Override
    public void setDefaultType(@Nullable final MPResultType defaultType) {
        if (getDefaultType() == defaultType)
            return;

        super.setDefaultType( defaultType );
        getUser().setChanged();
    }

    @Override
    public void setHidePasswords(final boolean hidePasswords) {
        if (Objects.equals( isHidePasswords(), hidePasswords ))
            return;

        super.setHidePasswords( hidePasswords );
        getUser().setChanged();
    }
}
