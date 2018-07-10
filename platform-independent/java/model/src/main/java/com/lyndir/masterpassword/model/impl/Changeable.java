package com.lyndir.masterpassword.model.impl;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;


/**
 * @author lhunath, 2018-07-08
 */
public class Changeable {

    private static final ExecutorService changeExecutor = Executors.newSingleThreadExecutor();

    private boolean  changed;
    private Grouping grouping = Grouping.APPLY;

    void setChanged() {
        synchronized (changeExecutor) {
            if (changed)
                return;

            if (grouping != Grouping.IGNORE)
                changed = true;
            if (grouping != Grouping.APPLY)
                return;

            changeExecutor.submit( () -> {
                synchronized (changeExecutor) {
                    if (grouping != Grouping.APPLY)
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
            grouping = Grouping.BATCH;
        }
    }

    public void ignoreChanges() {
        synchronized (changeExecutor) {
            grouping = Grouping.IGNORE;
        }
    }

    public boolean endChanges() {
        synchronized (changeExecutor) {
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
