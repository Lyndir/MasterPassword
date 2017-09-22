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

package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import java.util.Objects;


/**
 * @author lhunath, 14-12-07
 */
public class MPSiteResult {

    private final MPFileSite site;

    public MPSiteResult(final MPFileSite site) {
        this.site = site;
    }

    public MPFileSite getSite() {
        return site;
    }

    @Override
    public boolean equals(final Object obj) {
        return (this == obj) || ((obj instanceof MPSiteResult) && Objects.equals( site, ((MPSiteResult) obj).site ));
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( site );
    }

    @Override
    public String toString() {
        return strf( "{MPSiteResult: %s}", site );
    }
}
