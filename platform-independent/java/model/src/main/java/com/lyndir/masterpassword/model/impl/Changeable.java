package com.lyndir.masterpassword.model.impl;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;


/**
 * @author lhunath, 2018-07-08
 */
public class Changeable {

    private static final ExecutorService changeExecutor = Executors.newSingleThreadExecutor();

    private boolean changed;
    private boolean batchingChanges;

    void setChanged() {
        synchronized (changeExecutor) {
            if (changed)
                return;
            changed = true;

            if (batchingChanges)
                return;

            changeExecutor.submit( () -> {
                synchronized (changeExecutor) {
                    if (batchingChanges)
                        return;
                    changed = false;
                }

                onChanged();
            } );
        }
    }

    protected void onChanged() {
    }

    public void beginChanges() {
        synchronized (changeExecutor) {
            batchingChanges = true;
        }
    }

    public boolean endChanges() {
        synchronized (changeExecutor) {
            batchingChanges = false;

            if (changed) {
                this.changed = false;
                setChanged();
                return true;
            } else
                return false;
        }
    }
}
