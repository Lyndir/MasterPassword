package com.lyndir.masterpassword.gui.util;

import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.TypeUtils;
import com.lyndir.masterpassword.gui.util.platform.BasePlatform;
import com.lyndir.masterpassword.gui.util.platform.IPlatform;
import java.lang.reflect.InvocationTargetException;
import java.util.Optional;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-07-29
 */
public final class Platform {

    private static final Logger    logger = Logger.get( Platform.class );
    private static final IPlatform activePlatform;

    static {
        IPlatform tryPlatform;
        if (null != (tryPlatform = construct( "com.lyndir.masterpassword.gui.util.platform.JDK9Platform" )))
            activePlatform = tryPlatform;

        else
            activePlatform = new BasePlatform();
    }

    @Nullable
    private static <T> T construct(final String typeName) {
        try {
            // AppleGUI adds support for macOS features.
            Optional<Class<T>> gui = TypeUtils.loadClass( typeName );
            if (gui.isPresent())
                return gui.get().getConstructor().newInstance();
        }
        catch (@SuppressWarnings("ErrorNotRethrown") final LinkageError ignored) {
        }
        catch (final IllegalAccessException | InstantiationException | NoSuchMethodException | InvocationTargetException e) {
            throw logger.bug( e );
        }

        return null;
    }

    public static IPlatform get() {
        return activePlatform;
    }
}
