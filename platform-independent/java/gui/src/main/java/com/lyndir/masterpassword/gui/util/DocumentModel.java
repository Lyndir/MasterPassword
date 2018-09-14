package com.lyndir.masterpassword.gui.util;

import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.function.Consumer;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import javax.swing.text.BadLocationException;
import javax.swing.text.Document;


/**
 * @author lhunath, 2018-08-24
 */
public class DocumentModel implements Selectable<String, DocumentModel> {

    private static final Logger logger = Logger.get( DocumentModel.class );

    private final Document document;

    @Nullable
    private DocumentListener documentListener;

    public DocumentModel(final Document document) {
        this.document = document;
    }

    @Nonnull
    public Document getDocument() {
        return document;
    }

    @Nullable
    public String getText() {
        try {
            return (document.getLength() > 0)? document.getText( 0, document.getLength() ): null;
        }
        catch (final BadLocationException e) {
            logger.wrn( "While getting text for model", e );
            return null;
        }
    }

    public void setText(@Nullable final String text) {
        try {
            if (document.getLength() > 0)
                document.remove( 0, document.getLength() );

            if (text != null)
                document.insertString( 0, text, null );
        }
        catch (final BadLocationException e) {
            logger.err( "While setting text for model", e );
        }
    }

    @Override
    public DocumentModel selection(@Nullable final Consumer<String> selectionConsumer) {
        if (documentListener != null)
            document.removeDocumentListener( documentListener );

        if (selectionConsumer != null)
            document.addDocumentListener( documentListener = new DocumentListener() {
                @Override
                public void insertUpdate(final DocumentEvent e) {
                    trigger();
                }

                @Override
                public void removeUpdate(final DocumentEvent e) {
                    trigger();
                }

                @Override
                public void changedUpdate(final DocumentEvent e) {
                    trigger();
                }

                private void trigger() {
                    selectionConsumer.accept( getText() );
                }
            } );

        return this;
    }

    @Override
    public DocumentModel selection(@Nullable final String selectedItem, @Nullable final Consumer<String> selectionConsumer) {
        setText( selectedItem );
        selection( selectionConsumer );

        if (selectionConsumer != null)
            selectionConsumer.accept( selectedItem );

        return this;
    }
}
