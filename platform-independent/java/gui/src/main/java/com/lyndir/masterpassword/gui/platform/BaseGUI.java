package com.lyndir.masterpassword.gui.platform;

import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.TypeUtils;
import com.lyndir.masterpassword.gui.util.Res;
import com.lyndir.masterpassword.gui.view.MasterPasswordFrame;
import java.lang.reflect.InvocationTargetException;
import java.util.Optional;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-07-28
 */
public class BaseGUI {

    private static final Logger logger = Logger.get( BaseGUI.class );

    private final MasterPasswordFrame frame = createFrame();

    public static BaseGUI createPlatformGUI() {
        BaseGUI jdk9GUI = construct( "com.lyndir.masterpassword.gui.platform.JDK9GUI" );
        if (jdk9GUI != null)
            return jdk9GUI;

        BaseGUI appleGUI = construct( "com.lyndir.masterpassword.gui.platform.AppleGUI" );
        if (appleGUI != null)
            return appleGUI;

        // Use platform-independent GUI.
        return new BaseGUI();
    }

    @Nullable
    private static BaseGUI construct(final String typeName) {
        try {
            // AppleGUI adds support for macOS features.
            Optional<Class<BaseGUI>> gui = TypeUtils.loadClass( typeName );
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

    protected MasterPasswordFrame createFrame() {
        return new MasterPasswordFrame();
    }

    public void open() {
        Res.ui( () -> frame.setVisible( true ) );
    }
}
