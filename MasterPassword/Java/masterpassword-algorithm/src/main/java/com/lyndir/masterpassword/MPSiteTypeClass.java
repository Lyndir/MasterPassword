package com.lyndir.masterpassword;

/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public enum MPSiteTypeClass {
    Generated( 1 << 4 ),
    Stored( 1 << 5 );

    private final int mask;

    MPSiteTypeClass(final int mask) {
        this.mask = mask;
    }

    public int getMask() {
        return mask;
    }
}
