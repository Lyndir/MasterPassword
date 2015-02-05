package com.lyndir.masterpassword.gui;

import com.google.common.collect.ImmutableList;
import com.lyndir.masterpassword.model.IncorrectMasterPasswordException;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-06-08
 */
public class IncognitoUser extends User {

    private final String fullName;
    private       char[] masterPassword;

    public IncognitoUser(final String fullName) {
        this.fullName = fullName;
    }

    public String getFullName() {
        return fullName;
    }

    @Nullable
    @Override
    protected char[] getMasterPassword() {
        return masterPassword;
    }

    @Override
    public void authenticate(final char[] masterPassword)
            throws IncorrectMasterPasswordException {
        this.masterPassword = masterPassword;
    }

    @Override
    public Iterable<Site> findSitesByName(final String siteName) {
        return ImmutableList.of();
    }

    @Override
    public void addSite(final Site site) {
    }
}
