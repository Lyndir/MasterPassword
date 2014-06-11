package com.lyndir.lhunath.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;


/**
 * @author lhunath, 2014-06-08
 */
public class User {

    private final String name;
    private final String masterPassword;
    private       byte[] key;

    public User(final String name, final String masterPassword) {
        this.name = name;
        this.masterPassword = masterPassword;
    }

    public String getName() {
        return name;
    }

    public boolean hasKey() {
        return key != null || (masterPassword != null && !masterPassword.isEmpty());
    }

    public byte[] getKey() {
        if (key == null) {
            if (!hasKey()) {
                throw new IllegalStateException( strf( "Master password unknown for user: %s", name ) );
            } else {
                key = MasterPassword.keyForPassword( masterPassword, name );
            }
        }

        return key;
    }

    @Override
    public int hashCode() {
        return name.hashCode();
    }

    @Override
    public String toString() {
        return name;
    }
}
