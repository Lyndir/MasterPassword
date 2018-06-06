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

package com.lyndir.masterpassword.gui.util;

import com.google.common.primitives.UnsignedInteger;
import javax.swing.*;


/**
 * @author lhunath, 2016-10-29
 */
public class UnsignedIntegerModel extends SpinnerNumberModel {

    private static final long serialVersionUID = 1L;

    public UnsignedIntegerModel() {
        this( UnsignedInteger.ZERO, UnsignedInteger.ZERO, UnsignedInteger.MAX_VALUE, UnsignedInteger.ONE );
    }

    public UnsignedIntegerModel(final UnsignedInteger value) {
        this( value, UnsignedInteger.ZERO, UnsignedInteger.MAX_VALUE, UnsignedInteger.ONE );
    }

    public UnsignedIntegerModel(final UnsignedInteger value, final UnsignedInteger minimum) {
        this( value, minimum, UnsignedInteger.MAX_VALUE, UnsignedInteger.ONE );
    }

    public UnsignedIntegerModel(final UnsignedInteger value, final UnsignedInteger minimum, final UnsignedInteger maximum) {
        this( value, minimum, maximum, UnsignedInteger.ONE );
    }

    @SuppressWarnings("TypeMayBeWeakened")
    public UnsignedIntegerModel(final UnsignedInteger value, final UnsignedInteger minimum, final UnsignedInteger maximum,
                                final UnsignedInteger stepSize) {
        super( value, minimum, maximum, stepSize );
    }

    @Override
    public UnsignedInteger getNumber() {
        return (UnsignedInteger) super.getNumber();
    }
}
