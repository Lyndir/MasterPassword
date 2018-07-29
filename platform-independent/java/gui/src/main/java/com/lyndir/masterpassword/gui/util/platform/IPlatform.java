package com.lyndir.masterpassword.gui.util.platform;

import java.io.File;


/**
 * @author lhunath, 2018-07-29
 */
public interface IPlatform {

    boolean installAppForegroundHandler(Runnable handler);

    boolean installAppReopenHandler(Runnable handler);

    boolean show(File file);
}
