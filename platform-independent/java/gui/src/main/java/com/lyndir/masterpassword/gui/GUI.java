package com.lyndir.masterpassword.gui;

import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.gui.util.Platform;
import com.lyndir.masterpassword.gui.util.Res;
import com.lyndir.masterpassword.gui.view.MasterPasswordFrame;


/**
 * @author lhunath, 2018-07-28
 */
public class GUI {

    private static final Logger logger = Logger.get( GUI.class );

    private final MasterPasswordFrame frame = new MasterPasswordFrame();

    public GUI() {
        Platform.get().installAppForegroundHandler( this::open );
        Platform.get().installAppReopenHandler( this::open );
    }

    public void open() {
        Res.ui( () -> frame.setVisible( true ) );
    }
}
