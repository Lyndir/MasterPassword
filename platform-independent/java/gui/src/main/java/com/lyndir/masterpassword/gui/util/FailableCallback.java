package com.lyndir.masterpassword.gui.util;

import com.google.common.util.concurrent.FutureCallback;
import com.lyndir.lhunath.opal.system.logging.Logger;


/**
 * @author lhunath, 2018-07-08
 */
public abstract class FailableCallback<T> implements FutureCallback<T> {

    private final Logger logger;

    protected FailableCallback(final Logger logger) {
        this.logger = logger;
    }

    @Override
    public void onFailure(final Throwable t) {
        logger.err( t, "Future failed." );
        onSuccess( null );
    }
}
