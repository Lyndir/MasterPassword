package com.lyndir.masterpassword.gui.view;

import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.gui.util.Components;
import com.lyndir.masterpassword.gui.util.Res;
import com.lyndir.masterpassword.model.impl.MPFileUserManager;
import java.awt.*;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;
import javax.swing.*;
import javax.swing.border.BevelBorder;


/**
 * @author lhunath, 2018-07-14
 */
@SuppressWarnings("serial")
public class MasterPasswordFrame extends JFrame {

    private static final Logger logger = Logger.get( MasterPasswordFrame.class );

    @SuppressWarnings("FieldCanBeLocal")
    private final Components.GradientPanel root        = Components.borderPanel( Res.colors().frameBg(), BoxLayout.PAGE_AXIS );
    private final UserContentPanel         userContent = new UserContentPanel();

    @SuppressWarnings("MagicNumber")
    public MasterPasswordFrame() {
        super( "Master Password" );

        setContentPane( root );
        root.add( new FilesPanel() );
        root.add( Components.strut() );

        JPanel userPanel = Components.panel( new BorderLayout( 0, 0 ) );
        userPanel.add( userContent.getUserToolbar(), BorderLayout.LINE_START );
        userPanel.add( userContent.getSiteToolbar(), BorderLayout.LINE_END );
        userPanel.add( Components.borderPanel(
                BorderFactory.createBevelBorder( BevelBorder.RAISED, Res.colors().controlBorder(), Res.colors().frameBg() ),
                Res.colors().controlBg(), BoxLayout.PAGE_AXIS, userContent ), BorderLayout.CENTER );
        root.add( userPanel );

        addComponentListener( new ComponentHandler() );
        setPreferredSize( new Dimension( 800, 560 ) );
        setDefaultCloseOperation( DISPOSE_ON_CLOSE );
        pack();

        setLocationRelativeTo( null );
        setLocationByPlatform( true );
    }

    private class ComponentHandler extends ComponentAdapter {

        @Override
        public void componentShown(final ComponentEvent e) {
            MPFileUserManager.get().reload();
            userContent.transferFocus();
        }
    }
}
