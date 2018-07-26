package com.lyndir.masterpassword.util;

import java.util.function.Consumer;
import java.util.function.Function;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-07-25
 */
public final class Utilities {

    @Nullable
    public static <T, R> R ifNotNull(@Nullable final T value, final Function<T, R> consumer) {
        if (value == null)
            return null;

        return consumer.apply( value );
    }

    public static <T> void ifNotNullDo(@Nullable final T value, final Consumer<T> consumer) {
        if (value != null)
            consumer.accept( value );
    }
}
