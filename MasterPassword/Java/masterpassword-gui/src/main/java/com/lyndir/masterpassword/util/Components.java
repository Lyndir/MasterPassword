package com.lyndir.masterpassword.util;

import com.lyndir.masterpassword.gui.Res;
import java.awt.*;
import javax.swing.*;
import javax.swing.border.Border;
import javax.swing.border.CompoundBorder;


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

    public static JPanel bordered(final JComponent component, final Border border) {
        return bordered( component, border, null );
    }

    public static JPanel bordered(final JComponent component, final Border border, Color background) {
        JPanel box = boxLayout( BoxLayout.LINE_AXIS, component );

        if (border != null)
            box.setBorder( border );

        if (background != null)
            box.setBackground( background );

        return box;
    }

    public static JTextField textField() {
        return new JTextField() {
            {
                setBorder( BorderFactory.createCompoundBorder( BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ),
                                                               BorderFactory.createEmptyBorder( 4, 4, 4, 4 ) ) );
                setFont( Res.valueFont().deriveFont( 12f ) );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
    }

    public static JPasswordField passwordField() {
        return new JPasswordField() {
            {
                setBorder( BorderFactory.createCompoundBorder( BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ),
                                                               BorderFactory.createEmptyBorder( 4, 4, 4, 4 ) ) );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
    }

    public static JButton button(String label) {
        return new JButton( label ) {
            {
                setFont( Res.controlFont().deriveFont( 12f ) );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( 20, getPreferredSize().height );
            }
        };
    }

    public static Component stud() {
        return Box.createRigidArea( new Dimension( 8, 8 ) );
    }

    public static JSpinner spinner(final SpinnerModel model) {
        return new JSpinner( model ) {
            {
                CompoundBorder editorBorder = BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ),
                        BorderFactory.createEmptyBorder( 4, 4, 4, 4 ) );
                ((DefaultEditor) getEditor()).getTextField().setBorder( editorBorder );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( 20, getPreferredSize().height );
            }
        };
    }

    public static JLabel label(final String label) {
        return label( label, JLabel.LEADING );
    }

    public static JLabel label(final String label, final int alignment) {
        return new JLabel( label, alignment ) {
            {
                setFont( Res.controlFont().deriveFont( 12f ) );
            }
        };
    }

    public static JCheckBox checkBox(final String label) {
        return new JCheckBox( label ) {
            {
                setFont( Res.controlFont().deriveFont( 12f ) );
            }
        };
    }
}
