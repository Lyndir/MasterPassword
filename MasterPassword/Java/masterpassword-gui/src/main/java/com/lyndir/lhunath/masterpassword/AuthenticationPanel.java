package com.lyndir.lhunath.masterpassword;

import com.google.common.io.Resources;
import java.awt.*;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-11
 */
public abstract class AuthenticationPanel extends JPanel {

    protected final UnlockFrame unlockFrame;

    public AuthenticationPanel(final UnlockFrame unlockFrame) {
        this.unlockFrame = unlockFrame;

        setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

        // Avatar
        add( Box.createVerticalGlue() );
        add( new JLabel( new ImageIcon( Resources.getResource( "media/Avatars/avatar-0.png" ) ) ) {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, Integer.MAX_VALUE );
            }
        } );
        add( Box.createVerticalGlue() );
    }

    protected void updateUser() {
        unlockFrame.setUser( getUser() );
    }

    protected abstract User getUser();

    public Component getFocusComponent() {
        return null;
    }
}
