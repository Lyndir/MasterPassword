package com.lyndir.masterpassword.gui.util;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Charsets;
import com.google.common.io.ByteSource;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.ObjectUtils;
import com.lyndir.masterpassword.gui.MPGuiConfig;
import com.lyndir.masterpassword.model.MPUser;
import java.io.IOException;
import java.io.InputStream;
import java.net.*;
import java.util.Collection;
import java.util.concurrent.CopyOnWriteArraySet;
import javax.annotation.Nullable;
import javax.swing.*;


public class State {

    private static final Logger logger   = Logger.get( State.class );
    private static final State  instance = new State();

    private final Collection<Listener> listeners = new CopyOnWriteArraySet<>();
    @Nullable
    private       MPUser<?>            activeUser;

    public static State get() {
        return instance;
    }

    public void addListener(final Listener listener) {
        if (listeners.add( listener ))
            listener.onUserSelected( activeUser );
    }

    public void removeListener(final Listener listener) {
        listeners.remove( listener );
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
        return State.class.getPackage().getImplementationVersion();
    }

    public void updateCheck() {
        if (!MPGuiConfig.get().checkForUpdates())
            return;

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

    @SuppressWarnings("InterfaceMayBeAnnotatedFunctional")
    public interface Listener {

        void onUserSelected(@Nullable MPUser<?> user);
    }
}
