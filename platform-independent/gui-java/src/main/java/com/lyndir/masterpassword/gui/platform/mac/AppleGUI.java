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

package com.lyndir.masterpassword.gui.platform.mac;

import com.apple.eawt.*;
import com.lyndir.masterpassword.gui.GUI;
import com.lyndir.masterpassword.gui.view.PasswordFrame;
import com.lyndir.masterpassword.gui.model.User;

import javax.swing.*;


/**
 * @author lhunath, 2014-06-10
 */
public class AppleGUI extends GUI {

    public AppleGUI() {

        try {
            Application application = Application.getApplication();
            application.addAppEventListener(new AppForegroundListener() {

                @Override
                public void appMovedToBackground(final AppEvent.AppForegroundEvent arg0) {
                }

                @Override
                public void appRaisedToForeground(final AppEvent.AppForegroundEvent arg0) {
                    open();
                }
            });
            application.addAppEventListener(new AppReOpenedListener() {
                @Override
                public void appReOpened(final AppEvent.AppReOpenedEvent arg0) {
                    open();
                }
            });
        } catch (Throwable t) {
            unlockFrame.dispose();
            throw t;
        }
    }

    @Override
    protected PasswordFrame newPasswordFrame(final User user) {
        PasswordFrame frame = super.newPasswordFrame( user );
        frame.setDefaultCloseOperation( WindowConstants.HIDE_ON_CLOSE );

        return frame;
    }
}
