package com.lyndir.masterpassword.gui.util.platform;

import java.io.File;


/**
 * @author lhunath, 2018-07-29
 */
public class BasePlatform implements IPlatform {

    @Override
    public boolean installAppForegroundHandler(final Runnable handler) {
        return false;
    }

    @Override
    public boolean installAppReopenHandler(final Runnable handler) {
        return false;
    }

    @Override
    public boolean show(final File file) {
        return false;
    }
}
