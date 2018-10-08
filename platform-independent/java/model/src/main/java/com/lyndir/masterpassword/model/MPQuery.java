package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.ImmutableCollection;
import com.google.common.collect.ImmutableList;
import java.util.*;
import java.util.function.Function;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


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
    public <V> Optional<Result<V>> matches(final V value, final CharSequence key) {
        Result<V> result = Result.noneOf( value, key );
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

        // If the match against the query broke before the end of the query, it failed.
        return (q < query.length())? Optional.empty(): Optional.of( result );
    }

    /**
     * @return Results for values that matched against the query, in the original values' order.
     */
    @Nonnull
    public <V> ImmutableCollection<Result<? extends V>> find(final Iterable<? extends V> values,
                                                             final Function<V, CharSequence> valueToKey) {
        ImmutableList.Builder<Result<? extends V>> results = ImmutableList.builder();
        for (final V value : values)
            matches( value, valueToKey.apply( value ) ).ifPresent( results::add );

        return results.build();
    }

    public static class Result<V> {

        private final V            value;
        private final CharSequence key;
        private final boolean[]    keyMatches;

        Result(final V value, final CharSequence key) {
            this.value = value;
            this.key = key;

            keyMatches = new boolean[key.length()];
        }

        public static <T> Result<T> noneOf(final T value, final CharSequence key) {
            return new Result<>( value, key );
        }

        public static <T> Result<T> allOf(final T value, final CharSequence key) {
            Result<T> result = noneOf( value, key );
            Arrays.fill( result.keyMatches, true );
            return result;
        }

        @Nonnull
        public V getValue() {
            return value;
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
        public boolean equals(final Object o) {
            if (!(o instanceof Result))
                return false;

            Result<?> r = (Result<?>) o;
            return Objects.equals( value, r.value ) && Objects.equals( key, r.key ) && Arrays.equals( keyMatches, r.keyMatches );
        }

        @Override
        public int hashCode() {
            return getValue().hashCode();
        }

        @Override
        public String toString() {
            return strf( "{Result: %s}", key );
        }
    }
}
