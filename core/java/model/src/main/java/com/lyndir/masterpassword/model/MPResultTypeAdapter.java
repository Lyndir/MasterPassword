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

import com.google.gson.*;
import com.lyndir.masterpassword.MPResultType;
import java.lang.reflect.Type;


/**
 * @author lhunath, 2018-04-27
 */
public class MPResultTypeAdapter implements JsonSerializer<MPResultType>, JsonDeserializer<MPResultType> {

    @Override
    public MPResultType deserialize(final JsonElement json, final Type typeOfT, final JsonDeserializationContext context)
            throws JsonParseException {
        try {
            return MPResultType.forType( json.getAsInt() );
        }
        catch (final ClassCastException | IllegalStateException e) {
            throw new JsonParseException( "Not an ordinal value: " + json, e );
        }
    }

    @Override
    public JsonElement serialize(final MPResultType src, final Type typeOfSrc, final JsonSerializationContext context) {
        return new JsonPrimitive( src.getType() );
    }
}
