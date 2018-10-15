package com.lyndir.masterpassword.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.google.common.collect.ClassToInstanceMap;
import com.google.common.collect.MutableClassToInstanceMap;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.model.impl.Changeable;
import com.lyndir.masterpassword.model.impl.MPJSONAnyObject;
import java.io.File;
import java.io.IOException;


/**
 * @author lhunath, 2018-10-14
 */
@SuppressWarnings("CallToSystemGetenv")
public class MPConfig extends MPJSONAnyObject {

    private static final Logger                       logger     = Logger.get( MPConfig.class );
    private static final ClassToInstanceMap<MPConfig> instances  = MutableClassToInstanceMap.create();
    private static final File                         configFile = new File( rcDir(), "config.json" );

    private final        Changeable                   changeable = new Changeable() {
        @Override
        protected void onChanged() {
            try {
                objectMapper.writerWithDefaultPrettyPrinter().writeValue( configFile, MPConfig.this );
                instances.clear();
            }
            catch (final IOException e) {
                logger.err( e, "While saving config to: %s", configFile );
            }
        }
    };

    protected static synchronized <C extends MPConfig> C get(final Class<C> type) {
        C instance = instances.getInstance( type );

        if (instance == null)
            if (configFile.exists())
                try {
                    instances.putInstance( type, instance = objectMapper.readValue( configFile, type ) );
                }
                catch (final IOException e) {
                    logger.wrn( e, "While reading config file: %s", configFile );
                }

        if (instance == null)
            try {
                instance = type.getConstructor().newInstance();
            }
            catch (final ReflectiveOperationException e) {
                throw logger.bug( e );
            }

        return instance;
    }

    protected void setChanged() {
        changeable.setChanged();
    }

    public static MPConfig get() {
        return get( MPConfig.class );
    }

    public static File rcDir() {
        String rcDir = System.getenv( MPModelConstants.env_rcDir );
        if (rcDir != null)
            return new File( rcDir );

        String home = System.getProperty( "user.home" );
        if (home == null)
            home = System.getenv( "HOME" );

        return new File( home, ".mpw.d" );
    }
}
