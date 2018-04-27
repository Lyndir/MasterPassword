//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

package com.lyndir.masterpassword;

import android.os.Handler;
import android.os.Looper;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Sets;
import java.util.List;
import java.util.Set;
import java.util.concurrent.*;
import javax.annotation.Nonnull;


/**
 * @author lhunath, 2015-12-22
 */
public class MainThreadExecutor extends AbstractExecutorService {

    private final Handler       mHandler = new Handler( Looper.getMainLooper() );
    private final Set<Runnable> commands = Sets.newLinkedHashSet();
    private       boolean       shutdown;

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

    @Nonnull
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
