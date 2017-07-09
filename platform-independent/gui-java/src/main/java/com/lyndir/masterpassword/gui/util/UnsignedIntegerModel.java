package com.lyndir.masterpassword.gui.util;

import com.google.common.primitives.UnsignedInteger;
import javax.swing.*;


/**
 * @author lhunath, 2016-10-29
 */
public class UnsignedIntegerModel extends SpinnerNumberModel {

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

    public UnsignedIntegerModel(final UnsignedInteger value, final UnsignedInteger minimum, final UnsignedInteger maximum,
                                final UnsignedInteger stepSize) {
        super( value.doubleValue(), minimum.doubleValue(), maximum.doubleValue(), stepSize.doubleValue() );
    }

    @Override
    public UnsignedInteger getNumber() {
        return UnsignedInteger.valueOf( super.getNumber().longValue() );
    }
}
