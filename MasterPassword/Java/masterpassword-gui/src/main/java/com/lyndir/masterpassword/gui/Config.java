package com.lyndir.masterpassword.gui;

import com.lyndir.lhunath.opal.system.util.ConversionUtils;


/**
 * @author lhunath, 2014-08-31
 */
public class Config {

    private static final Config instance = new Config();

    public static Config get() {
        return instance;
    }

    public boolean checkForUpdates() {
        return ConversionUtils.toBoolean( System.getProperty( "mp.update.check" ) ).or( true );
    }
}
