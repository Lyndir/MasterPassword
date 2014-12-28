package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.base.Function;
import com.google.common.collect.FluentIterable;
import com.lyndir.lhunath.opal.system.util.ObjectUtils;
import com.lyndir.masterpassword.MasterKey;
import com.lyndir.masterpassword.model.*;
import javax.annotation.Nullable;
import org.jetbrains.annotations.NotNull;


/**
 * @author lhunath, 14-12-08
 */
public class ModelUser extends User {

    private final MPUser model;
    private       String masterPassword;

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

    @Override
    protected String getMasterPassword() {
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

    public void setMasterPassword(final String masterPassword) {
        this.masterPassword = masterPassword;
    }

    @NotNull
    @Override
    public MasterKey getKey() throws MasterKeyException {
        MasterKey key = super.getKey();
        if (!model.hasKeyID()) {
            model.setKeyID( key.getKeyID() );
            MPUserFileManager.get().save();
        } else if (!model.hasKeyID( key.getKeyID() ))
            throw new MasterKeyException( strf( "Incorrect master password for user: %s", getFullName() ) );

        return key;
    }

    @Override
    public Iterable<Site> findSitesByName(final String query) {
        return FluentIterable.from( model.findSitesByName( query ) ).transform( new Function<MPSiteResult, Site>() {
            @Nullable
            @Override
            public Site apply(final MPSiteResult result) {
                return new ModelSite( result );
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
        return false;
    }
}
