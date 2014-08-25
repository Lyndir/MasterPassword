package com.lyndir.masterpassword.model;

import com.lyndir.masterpassword.R;


/**
 * @author lhunath, 2014-08-20
 */
public enum Avatar {
    ZERO( R.drawable.avatar0 ),
    ONE( R.drawable.avatar1 ),
    TWO( R.drawable.avatar2 ),
    THREE( R.drawable.avatar3 ),
    FOUR( R.drawable.avatar4 ),
    FIVE( R.drawable.avatar5 ),
    SIX( R.drawable.avatar6 ),
    SEVEN( R.drawable.avatar7 ),
    EIGHT( R.drawable.avatar8 ),
    NINE( R.drawable.avatar9 ),
    TEN( R.drawable.avatar10 ),
    ELEVEN( R.drawable.avatar11 ),
    TWELVE( R.drawable.avatar12 ),
    THIRTEEN( R.drawable.avatar13 ),
    FOURTEEN( R.drawable.avatar14 ),
    FIFTEEN( R.drawable.avatar15 ),
    SIXTEEN( R.drawable.avatar16 ),
    SEVENTEEN( R.drawable.avatar17 ),
    EIGHTEEN( R.drawable.avatar18 );

    private final int imageResource;

    Avatar(final int imageResource) {
        this.imageResource = imageResource;
    }

    public int getImageResource() {
        return imageResource;
    }
}
