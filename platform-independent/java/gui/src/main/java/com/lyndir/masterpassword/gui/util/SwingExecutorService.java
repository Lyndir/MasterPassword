package com.lyndir.masterpassword.gui.util;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.google.common.collect.*;
import java.util.List;
import java.util.concurrent.*;
import javax.swing.*;
import org.jetbrains.annotations.NotNull;


/**
 * @author lhunath, 2018-07-08
 */
public class SwingExecutorService extends AbstractExecutorService {

    private final List<Runnable>         pendingCommands = Lists.newLinkedList();
    private final BlockingQueue<Boolean> terminated      = Queues.newLinkedBlockingDeque( 1 );
    private final boolean                immediate;
    private       boolean                shutdown;

    /**
     * @param immediate Allow immediate execution of the job in {@link #execute(Runnable)} if already on the right thread.
     *                  If {@code false}, jobs are always posted for later execution on the event thread.
     */
    public SwingExecutorService(final boolean immediate) {
        this.immediate = immediate;
    }

    @Override
    public void shutdown() {
        synchronized (pendingCommands) {
            shutdown = true;

            if (pendingCommands.isEmpty())
                terminated.add( true );
        }
    }

    @NotNull
    @Override
    public List<Runnable> shutdownNow() {
        shutdown();

        synchronized (pendingCommands) {
            return ImmutableList.copyOf( pendingCommands );
        }
    }

    @Override
    public boolean isShutdown() {
        synchronized (pendingCommands) {
            return shutdown;
        }
    }

    @Override
    public boolean isTerminated() {
        return ifNotNullElse( terminated.peek(), false );
    }

    @Override
    public boolean awaitTermination(final long timeout, @NotNull final TimeUnit unit)
            throws InterruptedException {
        return ifNotNullElse( terminated.poll( timeout, unit ), false );
    }

    @Override
    public void execute(@NotNull final Runnable command) {
        synchronized (pendingCommands) {
            if (shutdown)
                throw new RejectedExecutionException( "Executor is shut down." );

            pendingCommands.add( command );
        }

        if (immediate && SwingUtilities.isEventDispatchThread())
            run( command );
        else
            SwingUtilities.invokeLater( () -> run( command ) );
    }

    private void run(final Runnable command) {
        command.run();

        synchronized (pendingCommands) {
            pendingCommands.remove( command );

            if (shutdown && pendingCommands.isEmpty())
                terminated.add( true );
        }
    }
}
