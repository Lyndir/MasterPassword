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

package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Charsets;
import com.google.common.io.ByteSource;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.ObjectUtils;
import com.lyndir.masterpassword.gui.util.*;
import com.lyndir.masterpassword.gui.view.MasterPasswordFrame;
import com.lyndir.masterpassword.model.MPUser;
import com.tulskiy.keymaster.common.Provider;
import java.awt.*;
import java.io.IOException;
import java.io.InputStream;
import java.net.*;
import java.util.Collection;
import java.util.concurrent.CopyOnWriteArraySet;
import javax.annotation.Nullable;
import javax.swing.*;


/**
 * <p> <i>Jun 10, 2008</i> </p>
 *
 * @author mbillemo
 */
public final class MasterPassword {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger         logger   = Logger.get( MasterPassword.class );
    private static final MasterPassword instance = new MasterPassword();

    private final Provider             keyMaster = Provider.getCurrentProvider( true );

    @Nullable
    private MasterPasswordFrame frame;

    public static MasterPassword get() {
        return instance;
    }

    public void open() {
        Res.ui( () -> {
            if (frame == null)
                frame = new MasterPasswordFrame();

            frame.setAlwaysOnTop( true );
            frame.setVisible( true );
            frame.setExtendedState( Frame.NORMAL );
            Platform.get().requestForeground();
            frame.setAlwaysOnTop( false );
        } );
    }

    public static void main(final String... args) {
        //Thread.setDefaultUncaughtExceptionHandler(
        //        (t, e) -> logger.bug( e, "Uncaught: %s", e.getLocalizedMessage() ) );

        // Set the system look & feel, if available.
        try {
            UIManager.setLookAndFeel( UIManager.getSystemLookAndFeelClassName() );
        }
        catch (final UnsupportedLookAndFeelException | ClassNotFoundException | InstantiationException | IllegalAccessException ignored) {
        }

        // Create and open the UI.
        get().open();
        get().updateResidence();

        // Background.
        State.get().updateCheck();
    }

    public void updateResidence() {
        Platform.get().installAppForegroundHandler( get()::open );
        Platform.get().installAppReopenHandler( get()::open );
        keyMaster.register( MPGuiConstants.ui_hotkey, hotKey -> get().open() );
    }
}
