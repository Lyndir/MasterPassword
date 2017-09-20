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

import com.google.common.base.Function;
import com.google.common.base.Preconditions;
import com.google.common.collect.FluentIterable;
import com.lyndir.masterpassword.gui.*;
import com.lyndir.masterpassword.model.*;
import java.util.Arrays;
import javax.annotation.Nullable;


/**
 * @author lhunath, 14-12-08
 */
public class ModelUser extends User {

    private final MPUser model;

    public ModelUser(final MPUser model) {
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
    public int getAvatar() {
        return model.getAvatar();
    }

    public void setAvatar(final int avatar) {
        model.setAvatar( avatar % Res.avatars());
        MPUserFileManager.get().save();
    }

    @Override
    public void authenticate(final char[] masterPassword)
            throws IncorrectMasterPasswordException {
        key = model.authenticate( masterPassword );
        MPUserFileManager.get().save();
    }

    @Override
    public Iterable<Site> findSitesByName(final String siteName) {
        return FluentIterable.from( model.findSitesByName( siteName ) ).transform( new Function<MPSiteResult, Site>() {
            @Nullable
            @Override
            public Site apply(@Nullable final MPSiteResult site) {
                return new ModelSite( Preconditions.checkNotNull( site ) );
            }
        } );
    }

    @Override
    public void addSite(final Site site) {
        model.addSite( new MPSite( model, site.getSiteName(), site.getSiteCounter(), site.getResultType() ) );
        model.updateLastUsed();
        MPUserFileManager.get().save();
    }

    @Override
    public void deleteSite(final Site site) {
        if (site instanceof ModelSite) {
            model.deleteSite(((ModelSite) site).getModel());
            MPUserFileManager.get().save();
        }
    }

    public boolean keySaved() {
        // TODO
        return false;
    }
}
