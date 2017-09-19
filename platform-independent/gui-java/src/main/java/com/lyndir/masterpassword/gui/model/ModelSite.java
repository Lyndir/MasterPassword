package com.lyndir.masterpassword.gui.model;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.MPResultType;
import com.lyndir.masterpassword.MasterKey;
import com.lyndir.masterpassword.model.*;


/**
 * @author lhunath, 14-12-16
 */
public class ModelSite extends Site {

    private final MPSite model;

    public ModelSite(final MPSiteResult result) {
        model = result.getSite();
    }

    public MPSite getModel() {
        return model;
    }

    @Override
    public String getSiteName() {
        return model.getSiteName();
    }

    @Override
    public void setSiteName(final String siteName) {
        model.setSiteName( siteName );
        MPUserFileManager.get().save();
    }

    @Override
    public MPResultType getResultType() {
        return model.getResultType();
    }

    @Override
    public void setResultType(final MPResultType resultType) {
        if (resultType != getResultType()) {
            model.setResultType( resultType );
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

    @Override
    public UnsignedInteger getSiteCounter() {
        return model.getSiteCounter();
    }

    @Override
    public void setSiteCounter(final UnsignedInteger siteCounter) {
        if (siteCounter.equals( getSiteCounter() )) {
            model.setSiteCounter( siteCounter );
            MPUserFileManager.get().save();
        }
    }

    public void use() {
        model.updateLastUsed();
        MPUserFileManager.get().save();
    }
}
