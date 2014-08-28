package com.lyndir.masterpassword.util;

import java.awt.*;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class Components {

    public static JPanel boxLayout(int axis, Component... components) {
        JPanel container = new JPanel();
        container.setLayout( new BoxLayout( container, axis ) );
        for (Component component : components)
            container.add( component );

        return container;
    }
}
