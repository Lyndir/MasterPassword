//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

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
        if (!siteCounter.equals( getSiteCounter() )) {
            model.setSiteCounter( siteCounter );
            MPUserFileManager.get().save();
        }
    }

    public void use() {
        model.updateLastUsed();
        MPUserFileManager.get().save();
    }
}
