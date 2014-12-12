package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.lyndir.masterpassword.MasterKey;
import com.lyndir.masterpassword.model.MPUser;
import com.lyndir.masterpassword.model.MPUserFileManager;


/**
 * @author lhunath, 14-12-08
 */
public class ModelUser extends User {

    private final MPUser user;
    private       String masterPassword;

    public ModelUser(MPUser user) {
        this.user = user;
    }

    @Override
    public String getFullName() {
        return user.getFullName();
    }

    @Override
    protected String getMasterPassword() {
        return masterPassword;
    }

    public void setMasterPassword(final String masterPassword) {
        this.masterPassword = masterPassword;
    }

    @Override
    public MasterKey getKey() {
        MasterKey key = super.getKey();
        if (!user.hasKeyID()) {
            user.setKeyID( key.getKeyID() );
            MPUserFileManager.get().save();
        }
        else if (!user.hasKeyID( key.getKeyID() ))
            throw new IllegalStateException( strf( "Incorrect master password for user: %s", getFullName() ) );

        return key;
    }

    public boolean keySaved() {
        return false;
    }
}
