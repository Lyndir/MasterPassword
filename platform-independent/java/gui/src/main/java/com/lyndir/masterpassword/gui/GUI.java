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
import com.lyndir.lhunath.opal.system.util.TypeUtils;
import com.lyndir.masterpassword.gui.util.Res;
import com.lyndir.masterpassword.gui.view.MasterPasswordFrame;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.net.*;
import java.util.Optional;
import javax.swing.*;


/**
 * <p> <i>Jun 10, 2008</i> </p>
 *
 * @author mbillemo
 */
public class GUI {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( GUI.class );

    private final MasterPasswordFrame frame = new MasterPasswordFrame();

    public static void main(final String... args) {
        Thread.setDefaultUncaughtExceptionHandler(
                (t, e) -> logger.bug( e, "Uncaught: %s", e.getLocalizedMessage() ) );

        if (Config.get().checkForUpdates())
            checkUpdate();

        // Try and set the system look & feel, if available.
        try {
            UIManager.setLookAndFeel( UIManager.getSystemLookAndFeelClassName() );
        }
        catch (final UnsupportedLookAndFeelException | ClassNotFoundException | InstantiationException | IllegalAccessException ignored) {
        }

        create().open();
    }

    private static GUI create() {
        try {
            // AppleGUI adds support for macOS features.
            Optional<Class<GUI>> appleGUI = TypeUtils.loadClass( "com.lyndir.masterpassword.gui.platform.mac.AppleGUI" );
            if (appleGUI.isPresent())
                return appleGUI.get().getConstructor().newInstance();
        }
        catch (@SuppressWarnings("ErrorNotRethrown") final LinkageError ignored) {
        }
        catch (final IllegalAccessException | InstantiationException | NoSuchMethodException | InvocationTargetException e) {
            throw logger.bug( e );
        }

        // Use platform-independent GUI.
        return new GUI();
    }

    private static void checkUpdate() {
        try {
            String implementationVersion = GUI.class.getPackage().getImplementationVersion();
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

            if ((implementationVersion != null) && (latestVersion != null) &&
                !implementationVersion.equalsIgnoreCase( latestVersion )) {
                logger.inf( "Implementation: <%s>", implementationVersion );
                logger.inf( "Latest        : <%s>", latestVersion );
                logger.wrn( "You are not running the current official version.  Please update from:%n%s",
                            "https://masterpassword.app/masterpassword-gui.jar" );
                JOptionPane.showMessageDialog( null,
                                               strf( "A new version of Master Password is available.%n "
                                                     + "Please download the latest version from %s",
                                                     "https://masterpassword.app" ),
                                               "Update Available", JOptionPane.INFORMATION_MESSAGE );
            }
        }
        catch (final IOException e) {
            logger.wrn( e, "Couldn't check for version update." );
        }
    }

    protected void open() {
        Res.ui( () -> {
            frame.setVisible( true );
        } );
    }
}
