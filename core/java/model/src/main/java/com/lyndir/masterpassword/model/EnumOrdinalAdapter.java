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
import java.lang.reflect.Type;


/**
 * @author lhunath, 2018-04-27
 */
public class EnumOrdinalAdapter implements JsonSerializer<Enum<?>>, JsonDeserializer<Enum<?>> {

    @Override
    @SuppressWarnings("unchecked")
    public Enum<?> deserialize(final JsonElement json, final Type typeOfT, final JsonDeserializationContext context)
            throws JsonParseException {
        Enum<?>[] enumConstants = ((Class<Enum<?>>) typeOfT).getEnumConstants();
        if (enumConstants == null)
            throw new JsonParseException( "Not an enum: " + typeOfT );

        try {
            int ordinal = json.getAsInt();
            if ((ordinal < 0) || (ordinal >= enumConstants.length))
                throw new JsonParseException( "No ordinal " + ordinal + " in enum: " + typeOfT );

            return enumConstants[ordinal];
        } catch (final ClassCastException | IllegalStateException e) {
            throw new JsonParseException( "Not an ordinal value: " + json, e );
        }
    }

    @Override
    public JsonElement serialize(final Enum<?> src, final Type typeOfSrc, final JsonSerializationContext context) {
        return new JsonPrimitive( src.ordinal() );
    }
}
