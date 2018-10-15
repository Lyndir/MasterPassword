package com.lyndir.masterpassword.gui.util.platform;

import java.io.File;
import java.net.URI;


/**
 * @author lhunath, 2018-07-29
 */
public class BasePlatform implements IPlatform {

    @Override
    public boolean installAppForegroundHandler(final Runnable handler) {
        return false;
    }

    @Override
    public boolean removeAppForegroundHandler() {
        return false;
    }

    @Override
    public boolean installAppReopenHandler(final Runnable handler) {
        return false;
    }

    @Override
    public boolean removeAppReopenHandler() {
        return false;
    }

    @Override
    public boolean requestForeground() {
        return false;
    }

    @Override
    public boolean show(final File file) {
        return false;
    }

    @Override
    public boolean open(final URI url) {
        return false;
    }
}
