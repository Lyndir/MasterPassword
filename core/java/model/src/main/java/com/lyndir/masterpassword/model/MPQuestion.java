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

import com.lyndir.masterpassword.*;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-05-15
 */
public interface MPQuestion extends Comparable<MPQuestion> {

    // -- Meta

    @Nonnull
    String getKeyword();

    // -- Algorithm

    @Nonnull
    MPResultType getType();

    void setType(MPResultType type);

    @Nonnull
    String getAnswer(@Nullable String state)
            throws MPKeyUnavailableException, MPAlgorithmException;

    // -- Relationship

    @Nonnull
    MPSite<?> getSite();
}
