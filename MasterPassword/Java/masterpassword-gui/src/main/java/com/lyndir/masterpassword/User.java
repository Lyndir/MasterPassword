package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;


/**
 * @author lhunath, 2014-06-08
 */
public class User {

    private final String    userName;
    private final String    masterPassword;
    private       MasterKey key;

    public User(final String userName, final String masterPassword) {
        this.userName = userName;
        this.masterPassword = masterPassword;
    }

    public String getUserName() {
        return userName;
    }

    public boolean hasKey() {
        return key != null || (masterPassword != null && !masterPassword.isEmpty());
    }

    public MasterKey getKey() {
        if (key == null) {
            if (!hasKey()) {
                throw new IllegalStateException( strf( "Master password unknown for user: %s", userName ) );
            } else {
                key = new MasterKey( userName, masterPassword );
            }
        }

        return key;
    }

    @Override
    public int hashCode() {
        return userName.hashCode();
    }

    @Override
    public String toString() {
        return userName;
    }
}
