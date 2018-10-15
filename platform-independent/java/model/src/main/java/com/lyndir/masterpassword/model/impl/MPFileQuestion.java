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

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.lyndir.masterpassword.*;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-05-14
 */
public class MPFileQuestion extends MPBasicQuestion {

    @Nullable
    private String answerState;

    @SuppressWarnings("TypeMayBeWeakened")
    public MPFileQuestion(final MPFileSite site, final String keyword,
                          @Nullable final MPResultType type, @Nullable final String answerState) {
        super( site, keyword, ifNotNullElse( type, site.getAlgorithm().mpw_default_answer_type() ) );

        this.answerState = answerState;
    }

    @Nullable
    public String getAnswerState() {
        return answerState;
    }

    @Nullable
    @Override
    public String getAnswer()
            throws MPKeyUnavailableException, MPAlgorithmException {
        return getAnswer( answerState );
    }

    public void setAnswer(final MPResultType type, @Nullable final String answer)
            throws MPKeyUnavailableException, MPAlgorithmException {
        setType( type );

        if (answer == null)
            this.answerState = null;
        else
            this.answerState = getSite().getState(
                    MPKeyPurpose.Recovery, getKeyword(), null, getType(), answer );

        setChanged();
    }

    public void use() {
        if (getSite() instanceof MPFileSite)
            ((MPFileSite) getSite()).use();
    }
}
