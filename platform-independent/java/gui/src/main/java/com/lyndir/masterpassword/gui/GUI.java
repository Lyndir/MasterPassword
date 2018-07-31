package com.lyndir.masterpassword.gui;

import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.gui.util.Platform;
import com.lyndir.masterpassword.gui.util.Res;
import com.lyndir.masterpassword.gui.view.MasterPasswordFrame;
import com.tulskiy.keymaster.common.Provider;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;


/**
 * @author lhunath, 2018-07-28
 */
public class GUI {

    private static final Logger logger = Logger.get( GUI.class );

    private final MasterPasswordFrame frame = new MasterPasswordFrame();

    public GUI() {
        Platform.get().installAppForegroundHandler( this::open );
        Platform.get().installAppReopenHandler( this::open );

        KeyStroke keyStroke = KeyStroke.getKeyStroke( KeyEvent.VK_P, InputEvent.CTRL_DOWN_MASK | InputEvent.META_DOWN_MASK );
        Provider.getCurrentProvider( true ).register( keyStroke, hotKey -> open() );
    }

    public void open() {
        Res.ui( () -> {
            frame.setAlwaysOnTop( true );
            frame.setVisible( true );
            frame.setExtendedState( Frame.NORMAL );
            frame.setAlwaysOnTop( false );
            Platform.get().requestForeground();
        } );
    }
}
