package com.lyndir.masterpassword.gui.util.platform;

import java.io.File;
import java.net.URI;
import java.net.URL;


/**
 * @author lhunath, 2018-07-29
 */
public interface IPlatform {

    boolean installAppForegroundHandler(Runnable handler);

    boolean removeAppForegroundHandler();

    boolean installAppReopenHandler(Runnable handler);

    boolean removeAppReopenHandler();

    boolean requestForeground();

    boolean show(File file);

    boolean open(URI url);
}
