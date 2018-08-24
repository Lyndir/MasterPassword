package com.lyndir.masterpassword.gui.util;

import java.util.function.Consumer;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-08-23
 */
public class ConsumingTrigger<T> implements Consumer<T> {

    private final Runnable trigger;

    @Nullable
    private T value;

    public ConsumingTrigger(final Runnable trigger) {
        this.trigger = trigger;
    }

    @Override
    public void accept(final T t) {
        value = t;

        trigger.run();
    }
}
