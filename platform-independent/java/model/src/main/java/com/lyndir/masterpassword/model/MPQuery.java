package com.lyndir.masterpassword.model;

import java.util.*;
import java.util.function.Function;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.jetbrains.annotations.NotNull;


/**
 * @author lhunath, 2018-09-11
 */
public class MPQuery {

    @Nonnull
    private final String query;

    public MPQuery(@Nullable final String query) {
        this.query = (query != null)? query: "";
    }

    @Nonnull
    public String getQuery() {
        return query;
    }

    /**
     * @return {@code true} if this query is contained wholly inside the given {@code key}.
     */
    @Nonnull
    public <T extends Comparable<? super T>> Optional<Result<T>> find(final T option, final Function<T, CharSequence> keyForOption) {
        CharSequence key    = keyForOption.apply( option );
        Result<T>    result = Result.noneOf( option, key );
        if (query.isEmpty())
            return Optional.of( result );
        if (key.length() == 0)
            return Optional.empty();

        // Consume query and key characters until one of them runs out, recording any matches against the result's key.
        int q = 0, k = 0;
        while ((q < query.length()) && (k < key.length())) {
            if (query.charAt( q ) == key.charAt( k )) {
                result.keyMatchedAt( k );
                ++q;
            }

            ++k;
        }

        // If query is consumed, the result is a hit.
        return (q >= query.length())? Optional.of( result ): Optional.empty();
    }

    public static class Result<T extends Comparable<? super T>> implements Comparable<Result<T>> {

        private final T            option;
        private final CharSequence key;
        private final boolean[]    keyMatches;

        Result(final T option, final CharSequence key) {
            this.option = option;
            this.key = key;

            keyMatches = new boolean[key.length()];
        }

        public static <T extends Comparable<? super T>> Result<T> noneOf(final T option, final CharSequence key) {
            return new Result<>( option, key );
        }

        public static <T extends Comparable<? super T>> Result<T> allOf(final T option, final CharSequence key) {
            Result<T> result = noneOf( option, key );
            Arrays.fill( result.keyMatches, true );
            return result;
        }

        @Nonnull
        public T getOption() {
            return option;
        }

        @Nonnull
        public CharSequence getKey() {
            return key;
        }

        public String getKeyAsHTML() {
            return getKeyAsHTML( "u" );
        }

        @SuppressWarnings({ "MagicCharacter", "HardcodedFileSeparator" })
        public String getKeyAsHTML(final String mark) {
            String        closeMark = mark.contains( " " )? mark.substring( 0, mark.indexOf( ' ' ) ): mark;
            StringBuilder html      = new StringBuilder();
            boolean       marked    = false;

            for (int i = 0; i < key.length(); ++i) {
                if (keyMatches[i] && !marked) {
                    html.append( '<' ).append( mark ).append( '>' );
                    marked = true;
                } else if (!keyMatches[i] && marked) {
                    html.append( '<' ).append( '/' ).append( closeMark ).append( '>' );
                    marked = false;
                }

                html.append( key.charAt( i ) );
            }

            if (marked)
                html.append( '<' ).append( '/' ).append( closeMark ).append( '>' );

            return html.toString();
        }

        public boolean[] getKeyMatches() {
            return keyMatches.clone();
        }

        public boolean isExact() {
            for (final boolean keyMatch : keyMatches)
                if (!keyMatch)
                    return false;

            return true;
        }

        private void keyMatchedAt(final int k) {
            keyMatches[k] = true;
        }

        @Override
        public int compareTo(@NotNull final Result<T> o) {
            return getOption().compareTo( o.getOption() );
        }

        @Override
        public boolean equals(final Object o) {
            if (!(o instanceof Result))
                return false;

            Result<?> r = (Result<?>) o;
            return Objects.equals( option, r.option ) && Objects.equals( key, r.key ) && Arrays.equals( keyMatches, r.keyMatches );
        }

        @Override
        public int hashCode() {
            return getOption().hashCode();
        }
    }
}
