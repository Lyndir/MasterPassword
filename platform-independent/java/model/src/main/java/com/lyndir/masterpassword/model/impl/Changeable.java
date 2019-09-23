package com.lyndir.masterpassword.model.impl;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;


/**
 * @author lhunath, 2018-07-08
 */
public abstract class Changeable {

    private static final ExecutorService changeExecutor = Executors.newSingleThreadExecutor();

    private final Object   mutex    = new Object();
    private       Grouping grouping = Grouping.APPLY;
    private       boolean  changed;

    protected abstract void onChanged();

    public void setChanged() {
        synchronized (mutex) {
            if (changed)
                return;

            if (grouping != Grouping.IGNORE)
                changed = true;
            if (grouping != Grouping.APPLY)
                return;
        }

        changeExecutor.submit( () -> {
            synchronized (mutex) {
                if (grouping != Grouping.APPLY)
                    return;
                changed = false;
            }

            onChanged();
        } );
    }

    public void beginChanges() {
        synchronized (mutex) {
            grouping = Grouping.BATCH;
        }
    }

    public void ignoreChanges() {
        synchronized (mutex) {
            grouping = Grouping.IGNORE;
        }
    }

    public boolean endChanges() {
        synchronized (mutex) {
            grouping = Grouping.APPLY;

            if (changed) {
                this.changed = false;
                setChanged();
                return true;
            } else
                return false;
        }
    }

    private enum Grouping {
        APPLY, BATCH, IGNORE
    }
}
