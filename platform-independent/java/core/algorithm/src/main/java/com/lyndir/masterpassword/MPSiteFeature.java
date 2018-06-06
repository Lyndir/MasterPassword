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

package com.lyndir.masterpassword;

/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public enum MPSiteFeature {
    // bit 10 - 15

    /**
     * Export the key-protected content data.
     */
    ExportContent( 1 << 10 ),

    /**
     * Never export content.
     */
    DevicePrivate( 1 << 11 ),

    /**
     * Don't use this as the primary authentication result type.
     */
    Alternative( 1 << 12 );

    MPSiteFeature(final int mask) {
        this.mask = mask;
    }

    private final int mask;

    public int getMask() {
        return mask;
    }
}
