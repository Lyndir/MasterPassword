package com.lyndir.masterpassword;

import com.google.common.collect.ImmutableList;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.List;


/**
 * @author lhunath, 14-12-02
 */
public enum MPElementVariant {
    Password( "The password to log in with.", "Doesn't currently use a context.", //
              ImmutableList.of( "p", "password" ), "com.lyndir.masterpassword" ),
    Login( "The username to log in as.", "Doesn't currently use a context.", //
           ImmutableList.of( "l", "login" ), "com.lyndir.masterpassword.login" ),
    Answer( "The answer to a security question.", "Empty for a universal site answer or\nthe most significant word(s) of the question.", //
            ImmutableList.of( "a", "answer" ), "com.lyndir.masterpassword.answer" );

    static final Logger logger = Logger.get( MPElementType.class );

    private final String       description;
    private final String       contextDescription;
    private final List<String> options;
    private final String       scope;

    MPElementVariant(final String description, final String contextDescription, final List<String> options, final String scope) {
        this.contextDescription = contextDescription;

        this.options = options;
        this.description = description;
        this.scope = scope;
    }

    public String getDescription() {
        return description;
    }

    public String getContextDescription() {
        return contextDescription;
    }

    public List<String> getOptions() {
        return options;
    }

    public String getScope() {
        return scope;
    }

    /**
     * @param option The option to select a variant with.  It is matched case insensitively.
     *
     * @return The variant registered for the given option.
     */
    public static MPElementVariant forOption(final String option) {

        for (final MPElementVariant variant : values())
            if (variant.getOptions().contains( option.toLowerCase() ))
                return variant;

        throw logger.bug( "No variant for option: %s", option );
    }
}
