package com.lyndir.masterpassword.gui;

import com.google.common.base.*;
import com.google.common.collect.FluentIterable;
import com.lyndir.masterpassword.model.*;
import java.util.Arrays;
import javax.annotation.*;


/**
 * @author lhunath, 14-12-08
 */
public class ModelUser extends User {

    private final MPUser model;

    @Nullable
    private char[] masterPassword;

    public ModelUser(MPUser model) {
        this.model = model;
    }

    public MPUser getModel() {
        return model;
    }

    @Override
    public String getFullName() {
        return model.getFullName();
    }

    @Nullable
    @Override
    protected char[] getMasterPassword() {
        return masterPassword;
    }

    @Override
    public int getAvatar() {
        return model.getAvatar();
    }

    public void setAvatar(final int avatar) {
        model.setAvatar( avatar % Res.avatars() );
        MPUserFileManager.get().save();
    }

    public void authenticate(final char[] masterPassword)
            throws IncorrectMasterPasswordException {
        putKey( model.authenticate( masterPassword ) );
        this.masterPassword = masterPassword;
    }

    @Override
    public void reset() {
        super.reset();

        if (masterPassword != null) {
            Arrays.fill( masterPassword, (char) 0 );
            masterPassword = null;
        }
    }

    @Override
    public Iterable<Site> findSitesByName(final String query) {
        return FluentIterable.from( model.findSitesByName( query ) ).transform( new Function<MPSiteResult, Site>() {
            @Nullable
            @Override
            public Site apply(@Nullable final MPSiteResult result) {
                return new ModelSite( Preconditions.checkNotNull( result ) );
            }
        } );
    }

    @Override
    public void addSite(final Site site) {
        model.addSite( new MPSite( model, site.getSiteName(), site.getSiteType(), site.getSiteCounter() ) );
        model.updateLastUsed();
        MPUserFileManager.get().save();
    }

    public boolean keySaved() {
        // TODO
        return false;
    }
}
