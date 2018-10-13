package com.lyndir.masterpassword.model.impl;

import com.lyndir.masterpassword.MPResultType;
import com.lyndir.masterpassword.model.MPUserPreferences;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-10-13
 */
public class MPBasicUserPreferences<U extends MPBasicUser<?>> implements MPUserPreferences {

    private final U user;

    @Nullable
    private MPResultType defaultType;
    private boolean      hidePasswords;

    public MPBasicUserPreferences(final U user) {
        this.user = user;
    }

    protected U getUser() {
        return user;
    }

    @Override
    public MPResultType getDefaultType() {
        return (defaultType != null)? defaultType: user.getAlgorithm().mpw_default_result_type();
    }

    @Override
    public void setDefaultType(@Nullable final MPResultType defaultType) {
        this.defaultType = defaultType;
    }

    @Override
    public boolean isHidePasswords() {
        return hidePasswords;
    }

    @Override
    public void setHidePasswords(final boolean hidePasswords) {
        this.hidePasswords = hidePasswords;
    }
}
