package com.lyndir.masterpassword.gui;

import com.google.common.collect.ImmutableList;
import com.lyndir.masterpassword.gui.util.Components;
import java.awt.*;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-11
 */
public abstract class AuthenticationPanel extends Components.GradientPanel {

    protected final UnlockFrame unlockFrame;
    protected final JLabel      avatarLabel;

    public AuthenticationPanel(final UnlockFrame unlockFrame) {
        super( null, null );
        this.unlockFrame = unlockFrame;

        setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

        // Avatar
        add( Box.createVerticalGlue() );
        add( avatarLabel = new JLabel( Res.avatar( 0 ) ) {
            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, Integer.MAX_VALUE );
            }
        } );
        add( Box.createVerticalGlue() );
    }

    protected void updateUser(boolean repack) {
        unlockFrame.updateUser( getSelectedUser() );
        validate();

        if (repack)
            unlockFrame.repack();
    }

    protected abstract User getSelectedUser();

    public abstract char[] getMasterPassword();

    public Component getFocusComponent() {
        return null;
    }

    public Iterable<? extends JButton> getButtons() {
        return ImmutableList.of();
    }

    public abstract void reset();
}
