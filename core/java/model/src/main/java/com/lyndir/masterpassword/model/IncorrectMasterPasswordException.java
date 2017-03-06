package com.lyndir.masterpassword.model;

/**
 * @author lhunath, 14-12-17
 */
public class IncorrectMasterPasswordException extends Exception {

    private final MPUser user;

    public IncorrectMasterPasswordException(final MPUser user) {
        super( "Incorrect master password for user: " + user.getFullName() );

        this.user = user;
    }

    public MPUser getUser() {
        return user;
    }
}
