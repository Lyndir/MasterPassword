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

package com.lyndir.masterpassword.gui.platform;

import com.lyndir.masterpassword.gui.view.MasterPasswordFrame;
import java.awt.*;
import java.awt.desktop.*;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-10
 */
@SuppressWarnings("Since15")
public class JDK9GUI extends BaseGUI {

    public JDK9GUI() {
        Desktop.getDesktop().addAppEventListener( new AppEventHandler() );
    }

    @Override
    protected MasterPasswordFrame createFrame() {
        MasterPasswordFrame frame = super.createFrame();
        frame.setDefaultCloseOperation( WindowConstants.HIDE_ON_CLOSE );
        return frame;
    }

    private class AppEventHandler implements AppForegroundListener, AppReopenedListener {

        @Override
        public void appRaisedToForeground(final AppForegroundEvent e) {
            open();
        }

        @Override
        public void appMovedToBackground(final AppForegroundEvent e) {
        }

        @Override
        public void appReopened(final AppReopenedEvent e) {
            open();
        }
    }
}
