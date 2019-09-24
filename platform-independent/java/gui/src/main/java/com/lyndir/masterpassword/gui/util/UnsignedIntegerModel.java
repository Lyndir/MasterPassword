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
import java.text.ParseException;
import java.util.function.Consumer;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.ChangeListener;


/**
 * @author lhunath, 2016-10-29
 */
@SuppressWarnings("serial")
public class UnsignedIntegerModel extends SpinnerNumberModel implements Selectable<UnsignedInteger, UnsignedIntegerModel> {

    @Nullable
    private ChangeListener changeListener;

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

    @Override
    public UnsignedInteger getMinimum() {
        return (UnsignedInteger) super.getMinimum();
    }

    @Override
    public UnsignedInteger getMaximum() {
        return (UnsignedInteger) super.getMaximum();
    }

    @Override
    public UnsignedInteger getStepSize() {
        return (UnsignedInteger) super.getStepSize();
    }

    @Override
    public UnsignedInteger getNextValue() {
        if ((getMaximum() == null) || (getMaximum().compareTo( getNumber() ) > 0))
            return getNumber().plus( getStepSize() );

        return getMaximum();
    }

    @Override
    public UnsignedInteger getPreviousValue() {
        if ((getMinimum() == null) || (getMinimum().compareTo( getNumber() ) < 0))
            return getNumber().minus( getStepSize() );

        return getMinimum();
    }

    @Override
    public UnsignedIntegerModel selection(@Nullable final Consumer<UnsignedInteger> selectionConsumer) {
        if (changeListener != null) {
            removeChangeListener( changeListener );
            changeListener = null;
        }

        if (selectionConsumer != null) {
            addChangeListener( changeListener = e -> selectionConsumer.accept( getNumber() ) );
            selectionConsumer.accept( getNumber() );
        }

        return this;
    }

    @Override
    public UnsignedIntegerModel selection(@Nullable final UnsignedInteger selectedItem,
                                          @Nullable final Consumer<UnsignedInteger> selectionConsumer) {
        if (changeListener != null) {
            removeChangeListener( changeListener );
            changeListener = null;
        }

        setValue( (selectedItem != null)? selectedItem: getMinimum() );
        return selection( selectionConsumer );
    }

    public JFormattedTextField.AbstractFormatter getFormatter() {
        return new JFormattedTextField.AbstractFormatter() {
            @Override
            @Nullable
            public Object stringToValue(@Nullable final String text) {
                return (text != null)? UnsignedInteger.valueOf( text ): null;
            }

            @Override
            @Nullable
            public String valueToString(final Object value) {
                return (value != null)? value.toString(): null;
            }
        };
    }
}
