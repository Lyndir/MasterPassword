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

import com.fasterxml.jackson.annotation.*;
import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;
import java.util.*;


/**
 * @author lhunath, 2018-05-14
 */
@JsonInclude(value = JsonInclude.Include.CUSTOM, valueFilter = MPJSONAnyObject.MPJSONEmptyValue.class)
class MPJSONAnyObject {

    @JsonAnySetter
    final Map<String, Object> any = new LinkedHashMap<>();

    @JsonAnyGetter
    public Map<String, Object> getAny() {
        return Collections.unmodifiableMap( any );
    }

    @SuppressWarnings("EqualsAndHashcode")
    public static class MPJSONEmptyValue {

        @Override
        @SuppressWarnings({ "ChainOfInstanceofChecks", "Contract" })
        @SuppressFBWarnings({"EQ_UNUSUAL","EQ_CHECK_FOR_OPERAND_NOT_COMPATIBLE_WITH_THIS", "HE_EQUALS_USE_HASHCODE"})
        public boolean equals(final Object obj) {
            if (obj instanceof Collection<?>)
                return ((Collection<?>) obj).isEmpty();
            if (obj instanceof Map<?, ?>)
                return ((Map<?, ?>) obj).isEmpty();
            if (obj instanceof MPJSONFile.Site.Ext)
                return ((MPJSONAnyObject) obj).any.isEmpty();

            return obj == null;
        }
    }
}
