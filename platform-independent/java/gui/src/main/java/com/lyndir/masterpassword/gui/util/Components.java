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

import com.google.common.base.Strings;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.net.URISyntaxException;
import java.util.Arrays;
import java.util.Collection;
import java.util.function.Consumer;
import java.util.function.Function;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.border.Border;
import javax.swing.border.CompoundBorder;
import javax.swing.event.HyperlinkEvent;
import javax.swing.text.*;
import javax.swing.undo.UndoableEdit;
import org.jetbrains.annotations.NonNls;


/**
 * @author lhunath, 2014-06-08
 */
@SuppressWarnings({ "SerializableStoresNonSerializable", "serial" })
public abstract class Components {

    private static final Logger logger = Logger.get( Components.class );

    public static final int TEXT_SIZE_HEADING = 19;
    public static final int TEXT_SIZE_CONTROL = 13;
    public static final int SIZE_MARGIN       = 12;
    public static final int SIZE_PADDING      = 8;

    public static GradientPanel panel(final Component... components) {
        GradientPanel panel = panel( BoxLayout.LINE_AXIS, null, components );
        panel.setLayout( new OverlayLayout( panel ) );
        return panel;
    }

    public static GradientPanel panel(final int axis, final Component... components) {
        return panel( axis, null, components );
    }

    public static GradientPanel panel(final int axis, @Nullable final Color background, final Component... components) {
        GradientPanel container = panel( null, background );
        container.setLayout( new BoxLayout( container, axis ) );
        for (final Component component : components)
            container.add( component );

        return container;
    }

    public static GradientPanel borderPanel(final int axis, final Component... components) {
        return borderPanel( marginBorder(), null, axis, components );
    }

    public static GradientPanel borderPanel(@Nullable final Border border, final int axis, final Component... components) {
        return borderPanel( border, null, axis, components );
    }

    public static GradientPanel borderPanel(@Nullable final Color background, final int axis, final Component... components) {
        return borderPanel( marginBorder(), background, axis, components );
    }

    public static GradientPanel borderPanel(@Nullable final Border border, @Nullable final Color background, final int axis,
                                            final Component... components) {
        GradientPanel box = panel( axis, background, components );
        if (border != null)
            box.setBorder( border );

        return box;
    }

    public static GradientPanel panel(@Nullable final LayoutManager layout) {
        return panel( layout, null );
    }

    public static GradientPanel panel(@Nullable final LayoutManager layout, @Nullable final Color color) {
        return new GradientPanel( layout, color );
    }

    public static int showDialog(@Nullable final Component owner, @Nullable final String title, final JOptionPane pane) {
        JDialog dialog = pane.createDialog( owner, title );
        dialog.setMinimumSize( new Dimension( 520, 0 ) );
        dialog.setModalityType( Dialog.ModalityType.DOCUMENT_MODAL );
        showDialog( dialog );

        Object selectedValue = pane.getValue();
        if (selectedValue == null)
            return JOptionPane.CLOSED_OPTION;

        Object[] options = pane.getOptions();
        if (options == null)
            return (selectedValue instanceof Integer)? (Integer) selectedValue: JOptionPane.CLOSED_OPTION;

        try {
            int option = Arrays.binarySearch( options, selectedValue );
            return (option < 0)? JOptionPane.CLOSED_OPTION: option;
        }
        catch (final ClassCastException ignored) {
            return JOptionPane.CLOSED_OPTION;
        }
    }

    @Nullable
    public static File showLoadDialog(@Nullable final Component owner, final String title) {
        return showFileDialog( owner, title, FileDialog.LOAD, null );
    }

    @Nullable
    public static File showSaveDialog(@Nullable final Component owner, final String title, final String fileName) {
        return showFileDialog( owner, title, FileDialog.SAVE, fileName );
    }

    @Nullable
    private static File showFileDialog(@Nullable final Component owner, final String title,
                                       final int mode, @Nullable final String fileName) {
        FileDialog fileDialog = new FileDialog( JOptionPane.getFrameForComponent( owner ), title, mode );
        fileDialog.setFile( fileName );
        fileDialog.setLocationRelativeTo( owner );
        fileDialog.setLocationByPlatform( true );
        fileDialog.setVisible( true );

        File[] selectedFiles = fileDialog.getFiles();
        return ((selectedFiles != null) && (selectedFiles.length > 0))? selectedFiles[0]: null;
    }

    public static void showDialog(@Nullable final Component owner, @Nullable final String title, final Container content) {
        JDialog dialog = new JDialog( (owner != null)? SwingUtilities.windowForComponent( owner ): null,
                                      title, Dialog.ModalityType.DOCUMENT_MODAL );
        dialog.setMinimumSize( new Dimension( 320, 0 ) );
        dialog.setLocationRelativeTo( owner );
        dialog.setContentPane( content );
    }

    private static void showDialog(final JDialog dialog) {
        // OpenJDK does not correctly implement this setting in native code.
        dialog.getRootPane().putClientProperty( "apple.awt.documentModalSheet", Boolean.TRUE );
        dialog.getRootPane().putClientProperty( "Window.style", "small" );
        dialog.pack();

        dialog.setLocationByPlatform( true );
        dialog.setVisible( true );
    }

    public static JTextField textField() {
        return textField( null );
    }

    public static JTextField textField(@Nullable final Document document) {
        return new JTextField( document, null, 0 ) {
            {
                setBorder( BorderFactory.createCompoundBorder( BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ),
                                                               BorderFactory.createEmptyBorder( 4, 4, 4, 4 ) ) );
                setFont( Res.fonts().valueFont( TEXT_SIZE_CONTROL ) );
                setAlignmentX( LEFT_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, Integer.MAX_VALUE );
            }
        };
    }

    public static JTextField textField(@Nullable final String text, @Nullable final Consumer<String> change) {
        return textField( new DocumentModel( new PlainDocument() ).selection( text, change ).getDocument() );
    }

    public static JTextArea textArea() {
        return new JTextArea() {
            {
                setBorder( BorderFactory.createCompoundBorder( BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ),
                                                               BorderFactory.createEmptyBorder( 4, 4, 4, 4 ) ) );
                setFont( Res.fonts().valueFont( TEXT_SIZE_CONTROL ) );
                setAlignmentX( LEFT_ALIGNMENT );

                setLineWrap( true );
                setRows( 3 );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, Integer.MAX_VALUE );
            }
        };
    }

    public static JPasswordField passwordField() {
        return new JPasswordField( new PlainDocument( new GapContent() {
            @Override
            public String getString(final int where, final int len)
                    throws BadLocationException {
                return "";
            }
        } ), null, 0 ) {
            {
                setBorder( BorderFactory.createCompoundBorder( BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ),
                                                               BorderFactory.createEmptyBorder( 4, 4, 4, 4 ) ) );
                setAlignmentX( LEFT_ALIGNMENT );
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
                setAlignmentX( LEFT_ALIGNMENT );
                setFont( Res.fonts().valueFont( TEXT_SIZE_CONTROL ) );
                setCellRenderer( new DefaultListCellRenderer() {
                    @Override
                    @SuppressWarnings({ "unchecked", "SerializableStoresNonSerializable" })
                    public Component getListCellRendererComponent(final JList<?> list, final Object value, final int index,
                                                                  final boolean isSelected, final boolean cellHasFocus) {
                        String label = valueTransformer.apply( (E) value );
                        super.getListCellRendererComponent(
                                list, Strings.isNullOrEmpty( label )? " ": label, index, isSelected, cellHasFocus );
                        setBorder( BorderFactory.createEmptyBorder( 2, 4, 2, 4 ) );

                        return this;
                    }
                } );
                Dimension cellSize = getCellRenderer().getListCellRendererComponent( this, null, 0, false, false ).getPreferredSize();
                setFixedCellWidth( cellSize.width );
                setFixedCellHeight( cellSize.height );

                if (model instanceof CollectionListModel)
                    ((CollectionListModel<E>) model).registerList( this );
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
            }
        };
    }

    public static JButton button(final String label, @Nullable final ActionListener actionListener) {
        return button( new AbstractAction( label ) {
            @Override
            public void actionPerformed(final ActionEvent e) {
                if (actionListener != null)
                    actionListener.actionPerformed( e );
            }

            @Override
            public boolean isEnabled() {
                return actionListener != null;
            }
        } );
    }

    public static JButton button(final Icon icon, @Nullable final ActionListener actionListener, @Nullable String toolTip) {
        JButton iconButton = button( new AbstractAction( null, icon ) {
            @Override
            public void actionPerformed(final ActionEvent e) {
                if (actionListener != null)
                    actionListener.actionPerformed( e );
            }

            @Override
            public boolean isEnabled() {
                return actionListener != null;
            }
        } );
        iconButton.setToolTipText( toolTip );
        iconButton.setFocusable( false );

        return iconButton;
    }

    public static JButton button(final Action action) {
        return new JButton( action ) {
            {
                setAlignmentX( LEFT_ALIGNMENT );

                if (getText() == null) {
                    setContentAreaFilled( false );
                    setBorderPainted( false );
                    setOpaque( false );
                }
            }
        };
    }

    public static Component strut() {
        return strut( SIZE_PADDING );
    }

    public static Component strut(final int size) {
        Dimension  studDimension = new Dimension( size, size );
        Box.Filler rigidArea     = new Box.Filler( studDimension, studDimension, studDimension );
        rigidArea.setAlignmentX( Component.LEFT_ALIGNMENT );
        rigidArea.setBackground( Color.red );
        return rigidArea;
    }

    public static int margin() {
        return SIZE_MARGIN;
    }

    public static Border marginBorder() {
        return marginBorder( margin() );
    }

    public static Border marginBorder(final int size) {
        return BorderFactory.createEmptyBorder( size, size, size, size );
    }

    public static JSpinner spinner(final SpinnerModel model) {
        return new JSpinner( model ) {
            {
                CompoundBorder editorBorder = BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder( Res.colors().controlBorder(), 1, true ),
                        BorderFactory.createEmptyBorder( 4, 4, 4, 4 ) );
                DefaultFormatterFactory formatterFactory = new DefaultFormatterFactory();
                if (model instanceof UnsignedIntegerModel)
                    formatterFactory.setDefaultFormatter( ((UnsignedIntegerModel) model).getFormatter() );
                ((DefaultEditor) getEditor()).getTextField().setFormatterFactory( formatterFactory );
                ((DefaultEditor) getEditor()).getTextField().setBorder( editorBorder );
                setAlignmentX( LEFT_ALIGNMENT );
                setBorder( null );
            }
        };
    }

    public static JLabel heading() {
        return heading( " " );
    }

    public static JLabel heading(final int horizontalAlignment) {
        return heading( " ", horizontalAlignment );
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
                setFont( getFont().deriveFont( Font.BOLD, TEXT_SIZE_HEADING ) );
                setAlignmentX( LEFT_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
    }

    public static JLabel label() {
        return label( " " );
    }

    public static JLabel label(final int horizontalAlignment) {
        return label( " ", horizontalAlignment );
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
                setAlignmentX( LEFT_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
    }

    public static JCheckBox checkBox(final String label) {
        return checkBox( label, false, null );
    }

    public static JCheckBox checkBox(final String label, final boolean selected, @Nullable final Consumer<Boolean> selectionConsumer) {
        return new JCheckBox( label ) {
            {
                setBackground( null );
                setAlignmentX( LEFT_ALIGNMENT );
                setSelected( selected );

                if (selectionConsumer != null)
                    addItemListener( e -> selectionConsumer.accept( isSelected() ) );
            }
        };
    }

    @SafeVarargs
    public static <E> JComboBox<E> comboBox(final Function<E, String> valueTransformer, final E... values) {
        return comboBox( new DefaultComboBoxModel<>( values ), valueTransformer );
    }

    public static <E> JComboBox<E> comboBox(final E[] values, final Function<E, String> valueTransformer,
                                            @Nullable final E selectedItem, @Nullable final Consumer<E> selectionConsumer) {
        return comboBox( new CollectionListModel<>( values ).selection( selectedItem, selectionConsumer ), valueTransformer );
    }

    public static <E> JComboBox<E> comboBox(final Collection<E> values, final Function<E, String> valueTransformer,
                                            @Nullable final Consumer<E> selectionConsumer) {
        return comboBox( new CollectionListModel<>( values ).selection( selectionConsumer ), valueTransformer );
    }

    public static <E> JComboBox<E> comboBox(final Collection<E> values, final Function<E, String> valueTransformer,
                                            @Nullable final E selectedItem, @Nullable final Consumer<E> selectionConsumer) {
        return comboBox( new CollectionListModel<>( values ).selection( selectedItem, selectionConsumer ), valueTransformer );
    }

    public static <E> JComboBox<E> comboBox(final ComboBoxModel<E> model, final Function<E, String> valueTransformer) {
        return new JComboBox<E>( model ) {
            {
                setFont( Res.fonts().valueFont( TEXT_SIZE_CONTROL ) );
                setBorder( BorderFactory.createEmptyBorder( 4, 0, 4, 0 ) );
                setRenderer( new DefaultListCellRenderer() {
                    @Override
                    @SuppressWarnings({ "unchecked", "SerializableStoresNonSerializable" })
                    public Component getListCellRendererComponent(final JList<?> list, final Object value, final int index,
                                                                  final boolean isSelected, final boolean cellHasFocus) {
                        String label = valueTransformer.apply( (E) value );
                        super.getListCellRendererComponent(
                                list, Strings.isNullOrEmpty( label )? " ": label, index, isSelected, cellHasFocus );
                        setBorder( BorderFactory.createEmptyBorder( 0, 4, 0, 4 ) );

                        return this;
                    }
                } );
                putClientProperty( "JComboBox.isPopDown", Boolean.TRUE );
                setAlignmentX( LEFT_ALIGNMENT );
            }

            @Override
            public Dimension getMaximumSize() {
                return new Dimension( Integer.MAX_VALUE, getPreferredSize().height );
            }
        };
    }

    public static JEditorPane linkLabel(@NonNls final String html) {
        return new JEditorPane( "text/html", "<html><body style='width:640;font-family:sans-serif'>" + html ) {
            {
                setOpaque( false );
                setEditable( false );
                addHyperlinkListener( event -> {
                    if (event.getEventType() == HyperlinkEvent.EventType.ACTIVATED)
                        try {
                            Platform.get().open( event.getURL().toURI() );
                        }
                        catch (final URISyntaxException e) {
                            logger.err( e, "After triggering hyperlink: %s", event );
                        }
                } );
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

        public GradientPanel(@Nullable final LayoutManager layout) {
            this( layout, null );
        }

        public GradientPanel(@Nullable final LayoutManager layout, @Nullable final Color gradientColor) {
            super( layout );
            if (getLayout() == null)
                setLayout( new BoxLayout( this, BoxLayout.PAGE_AXIS ) );

            setGradientColor( gradientColor );
            setBackground( null );
            setAlignmentX( LEFT_ALIGNMENT );
        }

        @Nullable
        public Color getGradientColor() {
            return gradientColor;
        }

        public void setGradientColor(@Nullable final Color gradientColor) {
            this.gradientColor = gradientColor;
            updatePaint();
        }

        @Override
        public void setBackground(@Nullable final Color bg) {
            super.setBackground( bg );
            setOpaque( bg != null );
        }

        @Override
        public void setBounds(final int x, final int y, final int width, final int height) {
            super.setBounds( x, y, width, height );
            updatePaint();
        }

        private void updatePaint() {
            if (gradientColor == null) {
                paint = null;
                return;
            }

            paint = new GradientPaint( new Point( 0, 0 ), gradientColor,
                                       new Point( getWidth(), getHeight() ), gradientColor.darker() );
            repaint();
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
