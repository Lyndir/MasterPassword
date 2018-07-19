//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

package com.lyndir.masterpassword.gui.util;

import com.lyndir.masterpassword.gui.Res;
import java.awt.*;
import java.util.function.Function;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.border.Border;
import javax.swing.border.CompoundBorder;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class Components {

    private static final float HEADING_TEXT_SIZE = 19f;
    private static final float CONTROL_TEXT_SIZE = 13f;

    public static GradientPanel boxPanel(final int axis, final Component... components) {
        GradientPanel container = gradientPanel( null, null );
        container.setLayout( new BoxLayout( container, axis ) );
        for (final Component component : components)
            container.add( component );

        return container;
    }

    public static GradientPanel borderPanel(@Nullable final Border border, final Component... components) {
        return borderPanel( border, null, components );
    }

    public static GradientPanel borderPanel(@Nullable final Border border, @Nullable final Color background,
                                            final Component... components) {
        GradientPanel box = boxPanel( BoxLayout.LINE_AXIS, components );

        if (border != null)
            box.setBorder( border );

        if (background != null)
            box.setBackground( background );

        return box;
    }

    public static GradientPanel gradientPanel(@Nullable final Color color, @Nullable final LayoutManager layout) {
        return new GradientPanel( layout, color ) {
            {
                setOpaque( color != null );
                setBackground( color );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
            }
        };
    }

    public static JTextField textField() {
        return new JTextField() {
            {
                setBorder( BorderFactory.createCompoundBorder( BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ),
                                                               BorderFactory.createEmptyBorder( 4, 4, 4, 4 ) ) );
                setFont( Res.fonts().valueFont().deriveFont( CONTROL_TEXT_SIZE ) );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
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
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
    }

    public static <E> JList<E> list(final ListModel<E> model, final Function<E, String> valueTransformer) {
        return new JList<E>( model ) {
            {
                setFont( Res.fonts().valueFont().deriveFont( CONTROL_TEXT_SIZE ) );
                setBorder( BorderFactory.createEmptyBorder( 4, 0, 4, 0 ) );
                setCellRenderer( new DefaultListCellRenderer() {
                    {
                        setBorder( BorderFactory.createEmptyBorder( 0, 4, 0, 4 ) );
                    }

                    @Override
                    @SuppressWarnings({ "unchecked", "SerializableStoresNonSerializable" })
                    public Component getListCellRendererComponent(final JList<?> list, final Object value, final int index,
                                                                  final boolean isSelected, final boolean cellHasFocus) {
                        return super.getListCellRendererComponent(
                                list, valueTransformer.apply( (E) value ), index, isSelected, cellHasFocus );
                    }
                } );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, Integer.MAX_VALUE );
            }
        };
    }

    public static JScrollPane scrollPane(final Component child) {
        return new JScrollPane( child ) {
            {
                setBorder( BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ) );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
            }
        };
    }

    public static JButton button(final String label) {
        return new JButton( label ) {
            {
                setFont( Res.fonts().controlFont().deriveFont( CONTROL_TEXT_SIZE ) );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( 20, getPreferredSize().height );
            }
        };
    }

    public static Component strut() {
        return strut( 8 );
    }

    public static Component strut(final int size) {
        Dimension  studDimension = new Dimension( size, size );
        Box.Filler rigidArea     = new Box.Filler( studDimension, studDimension, studDimension );
        rigidArea.setAlignmentX( Component.LEFT_ALIGNMENT );
        rigidArea.setAlignmentY( Component.BOTTOM_ALIGNMENT );
        rigidArea.setBackground( Color.red );
        return rigidArea;
    }

    public static JSpinner spinner(final SpinnerModel model) {
        return new JSpinner( model ) {
            {
                CompoundBorder editorBorder = BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ),
                        BorderFactory.createEmptyBorder( 4, 4, 4, 4 ) );
                ((DefaultEditor) getEditor()).getTextField().setBorder( editorBorder );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
                setBorder( null );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( 20, getPreferredSize().height );
            }
        };
    }

    public static JLabel heading(@Nullable final String heading) {
        return heading( heading, SwingConstants.CENTER );
    }

    /**
     * @param horizontalAlignment One of the following constants
     *                            defined in {@code SwingConstants}:
     *                            {@code LEFT},
     *                            {@code CENTER},
     *                            {@code RIGHT},
     *                            {@code LEADING} or
     *                            {@code TRAILING}.
     */
    public static JLabel heading(@Nullable final String heading, final int horizontalAlignment) {
        return new JLabel( heading, horizontalAlignment ) {
            {
                setFont( Res.fonts().controlFont().deriveFont( Font.BOLD, HEADING_TEXT_SIZE ) );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
    }

    public static JLabel label(@Nullable final String label) {
        return label( label, SwingConstants.LEADING );
    }

    /**
     * @param horizontalAlignment One of the following constants
     *                            defined in {@code SwingConstants}:
     *                            {@code LEFT},
     *                            {@code CENTER},
     *                            {@code RIGHT},
     *                            {@code LEADING} or
     *                            {@code TRAILING}.
     */
    public static JLabel label(@Nullable final String label, final int horizontalAlignment) {
        return new JLabel( label, horizontalAlignment ) {
            {
                setFont( Res.fonts().controlFont().deriveFont( CONTROL_TEXT_SIZE ) );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
    }

    public static JCheckBox checkBox(final String label) {
        return new JCheckBox( label ) {
            {
                setFont( Res.fonts().controlFont().deriveFont( CONTROL_TEXT_SIZE ) );
                setBackground( null );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
            }
        };
    }

    @SafeVarargs
    public static <E> JComboBox<E> comboBox(final Function<E, String> valueTransformer, final E... values) {
        return comboBox( new DefaultComboBoxModel<>( values ), valueTransformer );
    }

    public static <E> JComboBox<E> comboBox(final ComboBoxModel<E> model, final Function<E, String> valueTransformer) {
        return new JComboBox<E>( model ) {
            {
                setFont( Res.fonts().valueFont().deriveFont( CONTROL_TEXT_SIZE ) );
                setBorder( BorderFactory.createEmptyBorder( 4, 0, 4, 0 ) );
                setRenderer( new DefaultListCellRenderer() {
                    {
                        setBorder( BorderFactory.createEmptyBorder( 0, 4, 0, 4 ) );
                    }

                    @Override
                    @SuppressWarnings({ "unchecked", "SerializableStoresNonSerializable" })
                    public Component getListCellRendererComponent(final JList<?> list, final Object value, final int index,
                                                                  final boolean isSelected, final boolean cellHasFocus) {
                        return super.getListCellRendererComponent(
                                list, valueTransformer.apply( (E) value ), index, isSelected, cellHasFocus );
                    }
                } );
                setAlignmentX( LEFT_ALIGNMENT );
                setAlignmentY( BOTTOM_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
    }

    public static class GradientPanel extends JPanel {

        @Nullable
        private Color gradientColor;

        @Nullable
        private GradientPaint paint;

        public GradientPanel() {
            this( null, null );
        }

        public GradientPanel(@Nullable final Color gradientColor) {
            this( null, gradientColor );
        }

        public GradientPanel(@Nullable final LayoutManager layout, @Nullable final Color gradientColor) {
            super( layout );
            this.gradientColor = gradientColor;
            setBackground( null );
        }

        @Nullable
        public Color getGradientColor() {
            return gradientColor;
        }

        public void setGradientColor(@Nullable final Color gradientColor) {
            this.gradientColor = gradientColor;
            revalidate();
        }

        @Override
        public void doLayout() {
            super.doLayout();

            if (gradientColor != null) {
                paint = new GradientPaint( new Point( 0, 0 ), gradientColor, new Point( getWidth(), getHeight() ), gradientColor.darker() );
                repaint();
            }
        }

        @Override
        protected void paintComponent(final Graphics g) {
            super.paintComponent( g );

            if (paint != null) {
                ((Graphics2D) g).setPaint( paint );
                g.fillRect( 0, 0, getWidth(), getHeight() );
            }
        }
    }
}
