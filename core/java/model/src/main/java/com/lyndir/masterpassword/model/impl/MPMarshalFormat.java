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

/**
 * @author lhunath, 2017-09-20
 *
 * This enum is ordered from oldest to newest format, the latest being most preferred.
 */
public enum MPMarshalFormat {
    /**
     * Marshal using the line-based plain-text format.
     */
    Flat {
        @Override
        public MPMarshaller marshaller() {
            return new MPFlatMarshaller();
        }

        @Override
        public MPUnmarshaller unmarshaller() {
            return new MPFlatUnmarshaller();
        }

        @Override
        public String fileSuffix() {
            return ".mpsites";
        }
    },

    /**
     * Marshal using the JSON structured format.
     */
    JSON {
        @Override
        public MPMarshaller marshaller() {
            return new MPJSONMarshaller();
        }

        @Override
        public MPUnmarshaller unmarshaller() {
            return new MPJSONUnmarshaller();
        }

        @Override
        public String fileSuffix() {
            return ".mpsites.json";
        }
    };

    public static final MPMarshalFormat DEFAULT = JSON;

    public abstract MPMarshaller marshaller();

    public abstract MPUnmarshaller unmarshaller();

    @SuppressWarnings("MethodReturnAlwaysConstant")
    public abstract String fileSuffix();
}
