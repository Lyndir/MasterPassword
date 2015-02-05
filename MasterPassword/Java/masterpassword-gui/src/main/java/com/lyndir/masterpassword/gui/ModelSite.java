package com.lyndir.masterpassword.gui;

import com.lyndir.masterpassword.MPSiteType;
import com.lyndir.masterpassword.MasterKey;
import com.lyndir.masterpassword.model.*;


/**
 * @author lhunath, 14-12-16
 */
public class ModelSite extends Site {

    private final MPSite model;

    public ModelSite(final MPSiteResult result) {
        this.model = result.getSite();
    }

    public String getSiteName() {
        return model.getSiteName();
    }

    @Override
    public void setSiteName(final String siteName) {
        model.setSiteName( siteName );
        MPUserFileManager.get().save();
    }

    public MPSiteType getSiteType() {
        return model.getSiteType();
    }

    @Override
    public void setSiteType(final MPSiteType siteType) {
        if (siteType != getSiteType()) {
            model.setSiteType( siteType );
            MPUserFileManager.get().save();
        }
    }

    @Override
    public MasterKey.Version getAlgorithmVersion() {
        return model.getAlgorithmVersion();
    }

    @Override
    public void setAlgorithmVersion(final MasterKey.Version algorithmVersion) {
        if (algorithmVersion != getAlgorithmVersion()) {
            model.setAlgorithmVersion( algorithmVersion );
            MPUserFileManager.get().save();
        }
    }

    public int getSiteCounter() {
        return model.getSiteCounter();
    }

    @Override
    public void setSiteCounter(final int siteCounter) {
        if (siteCounter != getSiteCounter()) {
            model.setSiteCounter( siteCounter );
            MPUserFileManager.get().save();
        }
    }

    public void use() {
        model.updateLastUsed();
        MPUserFileManager.get().save();
    }
}
