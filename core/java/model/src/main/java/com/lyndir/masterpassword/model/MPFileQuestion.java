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

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.ifNotNullElse;

import com.lyndir.masterpassword.*;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-05-14
 */
public class MPFileQuestion extends MPQuestion {

    private final MPSite site;

    private String       keyword;
    @Nullable
    private String       state;
    private MPResultType type;

    public MPFileQuestion(final MPSite site, final String keyword, @Nullable final String state, @Nullable final MPResultType type) {
        this.site = site;
        this.keyword = keyword;
        this.state = state;
        this.type = ifNotNullElse( type, site.getAlgorithm().mpw_default_answer_type() );
    }

    @Override
    public MPSite getSite() {
        return site;
    }

    @Override
    public String getKeyword() {
        return keyword;
    }

    public void setKeyword(final String keyword) {
        this.keyword = keyword;
    }

    public void setAnswer(final MPResultType type, @Nullable final String answer)
            throws MPKeyUnavailableException {
        this.type = type;

        if (answer == null)
            this.state = null;
        else
            this.state = getSite().getState(
                    MPKeyPurpose.Recovery, getKeyword(), null, type, answer );
    }

    @Override
    public MPResultType getType() {
        return type;
    }

    public void setType(final MPResultType type) {
        this.type = type;
    }

    public String getAnswer()
            throws MPKeyUnavailableException {
        return getAnswer( state );
    }
}
