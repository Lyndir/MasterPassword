package com.lyndir.masterpassword.gui;

import com.google.common.collect.ImmutableList;
import com.lyndir.masterpassword.MasterKey;


/**
 * @author lhunath, 2014-06-08
 */
public class IncognitoUser extends User {

    private final String            fullName;
    private final String            masterPassword;
    private       MasterKey.Version algorithmVersion;

    public IncognitoUser(final String fullName, final String masterPassword) {
        this.fullName = fullName;
        this.masterPassword = masterPassword;
    }

    public String getFullName() {
        return fullName;
    }

    @Override
    protected String getMasterPassword() {
        return masterPassword;
    }

    @Override
    public MasterKey.Version getAlgorithmVersion() {
        return algorithmVersion;
    }

    @Override
    public void setAlgorithmVersion(final MasterKey.Version algorithmVersion) {
        this.algorithmVersion = algorithmVersion;
    }

    @Override
    public Iterable<Site> findSitesByName(final String siteName) {
        return ImmutableList.of();
    }

    @Override
    public void addSite(final Site site) {
    }
}
