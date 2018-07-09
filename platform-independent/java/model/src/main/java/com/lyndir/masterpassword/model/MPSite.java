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

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.*;
import java.util.Collection;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-05-14
 */
public interface MPSite<Q extends MPQuestion> extends Comparable<MPSite<?>> {

    // - Meta

    @Nonnull
    String getName();

    void setName(String name);

    // - Algorithm

    @Nonnull
    MPAlgorithm getAlgorithm();

    void setAlgorithm(MPAlgorithm algorithm);

    @Nonnull
    UnsignedInteger getCounter();

    void setCounter(UnsignedInteger counter);

    @Nonnull
    MPResultType getResultType();

    void setResultType(MPResultType resultType);

    @Nonnull
    MPResultType getLoginType();

    void setLoginType(@Nullable MPResultType loginType);

    @Nonnull
    String getResult(MPKeyPurpose keyPurpose, @Nullable String keyContext, @Nullable String state)
            throws MPKeyUnavailableException, MPAlgorithmException;

    @Nonnull
    String getLogin(@Nullable String state)
            throws MPKeyUnavailableException, MPAlgorithmException;

    // - Relations

    @Nonnull
    MPUser<?> getUser();

    void addQuestion(Q question);

    void deleteQuestion(Q question);

    @Nonnull
    Collection<Q> getQuestions();
}
