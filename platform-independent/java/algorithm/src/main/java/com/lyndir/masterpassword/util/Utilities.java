package com.lyndir.masterpassword.util;

import java.util.function.Consumer;
import java.util.function.Function;
import javax.annotation.Nonnull;
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

    @Nonnull
    public static <T> T ifNotNullElse(@Nullable final T value, @Nonnull final T nullValue) {
        if (value == null)
            return nullValue;

        return value;
    }

    public static String ifNotNullOrEmptyElse(@Nullable final String value, @Nonnull final String emptyValue) {
        if ((value == null) || value.isEmpty())
            return emptyValue;

        return value;
    }

    @Nonnull
    public static <T, R> R ifNotNullElse(@Nullable final T value, final Function<T, R> consumer, @Nonnull final R nullValue) {
        if (value == null)
            return nullValue;

        return consumer.apply( value );
    }

    public static <T> void ifNotNullDo(@Nullable final T value, final Consumer<T> consumer) {
        if (value != null)
            consumer.accept( value );
    }
}
