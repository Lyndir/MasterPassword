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

package com.lyndir.masterpassword.model.impl;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.model.MPQuestion;
import com.lyndir.masterpassword.model.MPSite;
import java.util.Objects;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.jetbrains.annotations.NotNull;


/**
 * @author lhunath, 2018-05-14
 */
public abstract class MPBasicQuestion extends Changeable implements MPQuestion {

    private final MPSite<?> site;
    private final String    keyword;

    private MPResultType type;

    protected MPBasicQuestion(final MPSite<?> site, final String keyword, final MPResultType type) {
        this.site = site;
        this.keyword = keyword;
        this.type = type;
    }

    @Nonnull
    @Override
    public MPSite<?> getSite() {
        return site;
    }

    @Nonnull
    @Override
    public String getKeyword() {
        return keyword;
    }

    @Nonnull
    @Override
    public MPResultType getType() {
        return type;
    }

    @Override
    public void setType(final MPResultType type) {
        if (this.type == type)
            return;

        this.type = type;
        setChanged();
    }

    @Nullable
    @Override
    public String getAnswer(@Nullable final String state)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getSite().getResult( MPKeyPurpose.Recovery, getKeyword(), null, getType(), state );
    }

    @Override
    protected void onChanged() {
        if (site instanceof Changeable)
            ((Changeable) site).setChanged();
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( getKeyword() );
    }

    @Override
    public boolean equals(final Object obj) {
        return this == obj;
    }

    @Override
    public int compareTo(@NotNull final MPQuestion o) {
        return getKeyword().compareTo( o.getKeyword() );
    }

    @Override
    public String toString() {
        return strf( "{%s: %s}", getClass().getSimpleName(), getKeyword() );
    }
}
