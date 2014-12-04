package com.lyndir.masterpassword;

import static org.testng.Assert.*;

import org.testng.annotations.Test;


public class MasterKeyTest {

    private static final String FULL_NAME       = "Robert Lee Mitchell";
    private static final String MASTER_PASSWORD = "banana colored duckling";
    private static final String SITE_NAME       = "masterpasswordapp.com";

    @Test
    public void testEncode()
            throws Exception {

        MasterKey masterKey = new MasterKey( FULL_NAME, MASTER_PASSWORD );

        assertEquals( masterKey.encode( SITE_NAME, MPElementType.GeneratedLong, 1, MPElementVariant.Password, null ), //
                      "Jejr5[RepuSosp" );

        assertEquals( masterKey.encode( "\u26C4", MPElementType.GeneratedMaximum, 1, MPElementVariant.Password, null ), //
                      "bp7rJKc7kaXc4sxOwG0*" );

        assertEquals( masterKey.encode( "\u26C4", MPElementType.GeneratedLong, 1, MPElementVariant.Password, null ), //
                      "LiheCuwhSerz6)" );

        assertEquals( masterKey.encode( "\u26C4", MPElementType.GeneratedMedium, 1, MPElementVariant.Password, null ), //
                      "LihPih8+" );

        assertEquals( masterKey.encode( "\u26C4", MPElementType.GeneratedBasic, 1, MPElementVariant.Password, null ), //
                      "bpW62jmW" );

        assertEquals( masterKey.encode( "\u26C4", MPElementType.GeneratedShort, 1, MPElementVariant.Password, null ), //
                      "Lih6" );

        assertEquals( masterKey.encode( "\u26C4", MPElementType.GeneratedPIN, 1, MPElementVariant.Password, null ), //
                      "9216" );

        assertEquals( masterKey.encode( "\u26C4", MPElementType.GeneratedName, 1, MPElementVariant.Password, null ), //
                      "lihpihohi" );

        assertEquals( masterKey.encode( "\u26C4", MPElementType.GeneratedPhrase, 1, MPElementVariant.Password, null ), //
                      "li pihwe puz bemozno" );

        assertEquals( masterKey.encode( "\u26C4", MPElementType.GeneratedMaximum, (int) 4294967295L, MPElementVariant.Password, null ),
                      "r*)Ekr(FiduISCj*pg5-" );
    }

    @Test
    public void testGetUserName()
            throws Exception {

        assertEquals( new MasterKey( FULL_NAME, "banana colored duckling" ).getUserName(), FULL_NAME );
    }

    @Test
    public void testGetKeyID()
            throws Exception {

        assertEquals( new MasterKey( FULL_NAME, "banana colored duckling" ).getKeyID(),
                      "98EEF4D1DF46D849574A82A03C3177056B15DFFCA29BB3899DE4628453675302" );
    }

    @Test
    public void testInvalidate()
            throws Exception {

        try {
            MasterKey masterKey = new MasterKey( FULL_NAME, MASTER_PASSWORD );
            masterKey.invalidate();
            masterKey.encode( SITE_NAME, MPElementType.GeneratedLong, 1, MPElementVariant.Password, null );
            assertFalse( true, "Master key was not invalidated." );
        }
        catch (IllegalStateException ignored) {
        }
    }
}
