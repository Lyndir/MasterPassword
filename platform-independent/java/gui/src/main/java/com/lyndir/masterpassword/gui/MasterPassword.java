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
    private static final Logger logger = Logger.get( MasterPassword.class );

    private static final MasterPassword instance = new MasterPassword();

    private final Collection<Listener> listeners = new CopyOnWriteArraySet<>();
    private final MasterPasswordFrame frame = new MasterPasswordFrame();

    @Nullable
    private MPUser<?> activeUser;

    public static MasterPassword get() {
        return instance;
    }

    public boolean addListener(final Listener listener) {
        return listeners.add( listener );
    }

    public boolean removeListener(final Listener listener) {
        return listeners.remove( listener );
    }

    public void activateUser(final MPUser<?> user) {
        if (ObjectUtils.equals( activeUser, user ))
            return;

        activeUser = user;
        for (final Listener listener : listeners)
            listener.onUserSelected( activeUser );
    }

    @Nullable
    public String version() {
        return MasterPassword.class.getPackage().getImplementationVersion();
    }

    public void open() {
        Res.ui( () -> {
            frame.setAlwaysOnTop( true );
            frame.setVisible( true );
            frame.setExtendedState( Frame.NORMAL );
            Platform.get().requestForeground();
            frame.setAlwaysOnTop( false );
        } );
    }

    public void checkUpdate() {
        try {
            String implementationVersion = version();
            String latestVersion = new ByteSource() {
                @Override
                public InputStream openStream()
                        throws IOException {
                    URL           url  = URI.create( "https://masterpassword.app/masterpassword-gui.jar.rev" ).toURL();
                    URLConnection conn = url.openConnection();
                    conn.addRequestProperty( "User-Agent", "masterpassword-gui" );
                    return conn.getInputStream();
                }
            }.asCharSource( Charsets.UTF_8 ).readFirstLine();

            if ((implementationVersion != null) && !implementationVersion.equalsIgnoreCase( latestVersion )) {
                logger.inf( "Implementation: <%s>", implementationVersion );
                logger.inf( "Latest        : <%s>", latestVersion );
                logger.wrn( "You are not running the current official version.  Please update from:%n%s",
                            "https://masterpassword.app/masterpassword-gui.jar" );
                JOptionPane.showMessageDialog( null, Components.linkLabel( strf(
                        "A new version of Master Password is available."
                        + "<p>Please download the latest version from <a href='https://masterpassword.app'>https://masterpassword.app</a>." ) ),
                                               "Update Available", JOptionPane.INFORMATION_MESSAGE );
            }
        }
        catch (final IOException e) {
            logger.wrn( e, "Couldn't check for version update." );
        }
    }

    public static void main(final String... args) {
        //Thread.setDefaultUncaughtExceptionHandler(
        //        (t, e) -> logger.bug( e, "Uncaught: %s", e.getLocalizedMessage() ) );

        // Try and set the system look & feel, if available.
        try {
            UIManager.setLookAndFeel( UIManager.getSystemLookAndFeelClassName() );
            Platform.get().installAppForegroundHandler( get()::open );
            Platform.get().installAppReopenHandler( get()::open );
            Provider.getCurrentProvider( true ).register( MPGuiConstants.ui_hotkey, hotKey -> get().open() );
        }
        catch (final UnsupportedLookAndFeelException | ClassNotFoundException | InstantiationException | IllegalAccessException ignored) {
        }

        // Create a platform-specific GUI and open it.
        get().open();

        // Check online to see if this version has been superseded.
        if (MPConfig.get().checkForUpdates())
            get().checkUpdate();
    }

    @SuppressWarnings("InterfaceMayBeAnnotatedFunctional")
    public interface Listener {

        void onUserSelected(@Nullable MPUser<?> user);
    }
}
