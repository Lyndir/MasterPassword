package com.lyndir.masterpassword;

/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public enum MPSiteFeature {

    /**
     * Export the key-protected content data.
     */
    ExportContent( 1 << 10 ),

    /**
     * Never export content.
     */
    DevicePrivate( 1 << 11 );

    MPSiteFeature(final int mask) {
        this.mask = mask;
    }

    private final int mask;

    public int getMask() {
        return mask;
    }
}
