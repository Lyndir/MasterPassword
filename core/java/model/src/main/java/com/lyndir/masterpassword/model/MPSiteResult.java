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

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import java.util.Objects;
import org.jetbrains.annotations.NotNull;


/**
 * @author lhunath, 14-12-07
 */
public class MPSiteResult implements Comparable<MPSiteResult> {

    private final MPSite<?> site;

    public MPSiteResult(final MPSite<?> site) {
        this.site = site;
    }

    public MPSite<?> getSite() {
        return site;
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( getSite() );
    }

    @Override
    public boolean equals(final Object obj) {
        return (this == obj) || ((obj instanceof MPSiteResult) && Objects.equals( getSite(), ((MPSiteResult) obj).getSite() ));
    }

    @Override
    public int compareTo(@NotNull final MPSiteResult o) {
        return getSite().compareTo( o.getSite() );
    }

    @Override
    public String toString() {
        return strf( "{%s: %s}", getClass().getSimpleName(), getSite() );
    }
}
