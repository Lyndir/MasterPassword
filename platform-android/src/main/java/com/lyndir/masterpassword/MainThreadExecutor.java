package com.lyndir.masterpassword;

import android.os.Handler;
import android.os.Looper;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Sets;
import java.util.*;
import java.util.concurrent.*;


/**
 * @author lhunath, 2015-12-22
 */
public class MainThreadExecutor extends AbstractExecutorService {

    private final Handler       mHandler = new Handler( Looper.getMainLooper() );
    private final Set<Runnable> commands = Sets.newLinkedHashSet();
    private boolean shutdown;

    @Override
    public void execute(final Runnable command) {
        if (shutdown)
            throw new RejectedExecutionException( "This executor has been shut down" );

        synchronized (commands) {
            commands.add( command );

            mHandler.post( new Runnable() {
                @Override
                public void run() {
                    synchronized (commands) {
                        if (!commands.remove( command ))
                            // Command was removed, not executing.
                            return;
                    }

                    command.run();
                }
            } );
        }
    }

    @Override
    public void shutdown() {
        shutdown = true;
    }

    @Override
    public List<Runnable> shutdownNow() {
        shutdown = true;
        mHandler.removeCallbacksAndMessages( null );

        synchronized (commands) {
            ImmutableList<Runnable> pendingTasks = ImmutableList.copyOf( commands );
            commands.clear();
            commands.notifyAll();
            return pendingTasks;
        }
    }

    @Override
    public boolean isShutdown() {
        return shutdown;
    }

    @Override
    public boolean isTerminated() {
        synchronized (commands) {
            return shutdown && commands.isEmpty();
        }
    }

    @Override
    public boolean awaitTermination(final long timeout, final TimeUnit unit)
            throws InterruptedException {
        if (isTerminated())
            return true;

        commands.wait( unit.toMillis( timeout ) );
        return isTerminated();
    }
}
