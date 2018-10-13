package com.lyndir.masterpassword.model;

import com.lyndir.masterpassword.MPResultType;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-10-13
 */
public interface MPUserPreferences {

    MPResultType getDefaultType();

    void setDefaultType(@Nullable MPResultType defaultType);

    boolean isHidePasswords();

    void setHidePasswords(boolean hidePasswords);
}
