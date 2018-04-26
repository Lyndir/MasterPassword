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

package com.lyndir.masterpassword.gui.view;

import com.google.common.collect.ImmutableList;
import com.lyndir.masterpassword.gui.Res;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.model.MPUser;
import java.awt.*;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-11
 */
public abstract class AuthenticationPanel<U extends MPUser<?>> extends Components.GradientPanel {

    protected final UnlockFrame unlockFrame;
    protected final JLabel      avatarLabel;

    protected AuthenticationPanel(final UnlockFrame unlockFrame) {
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

        avatarLabel.setToolTipText( "The avatar for your user.  Click to change it." );
    }

    protected void updateUser(final boolean repack) {
        unlockFrame.updateUser( getSelectedUser() );
        validate();

        if (repack)
            unlockFrame.repack();
    }

    @Nullable
    protected abstract U getSelectedUser();

    @Nonnull
    public abstract char[] getMasterPassword();

    @Nullable
    public Component getFocusComponent() {
        return null;
    }

    public Iterable<? extends JButton> getButtons() {
        return ImmutableList.of();
    }

    public abstract void reset();

    public abstract PasswordFrame<?, ?> newPasswordFrame();
}
