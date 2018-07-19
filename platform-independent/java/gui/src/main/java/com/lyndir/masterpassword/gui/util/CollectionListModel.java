package com.lyndir.masterpassword.gui.util;

import com.google.common.collect.ImmutableList;
import java.util.*;
import javax.annotation.Nullable;
import javax.swing.*;


/**
 * @author lhunath, 2018-07-19
 */
@SuppressWarnings("serial")
public class CollectionListModel<E> extends AbstractListModel<E> implements ComboBoxModel<E> {

    private final List<E> model = new LinkedList<>();
    @Nullable
    private       E       selectedItem;

    public CollectionListModel() {
    }

    public CollectionListModel(final Collection<E> model) {
        this.model.addAll( model );
        fireIntervalAdded( this, 0, model.size() );
    }

    @Override
    public synchronized int getSize() {
        return model.size();
    }

    @Override
    public synchronized E getElementAt(final int index) {
        return model.get( index );
    }

    /**
     * Replace this model's contents with the objects from the new model collection.
     *
     * This operation will mutate the internal model to reflect the given model.
     * The given model will remain untouched and independent from this object.
     */
    @SuppressWarnings("AssignmentToForLoopParameter")
    public synchronized void set(final Collection<? extends E> newModel) {
        ImmutableList<? extends E> newModelList = ImmutableList.copyOf( newModel );

        ListIterator<E> oldIt = model.listIterator();
        for (int from = 0; oldIt.hasNext(); ++from) {
            int to = newModelList.indexOf( oldIt.next() );

            if (to != from) {
                oldIt.remove();
                fireIntervalRemoved( this, from, from );
                --from;
            }
        }

        Iterator<? extends E> newIt = newModelList.iterator();
        for (int to = 0; newIt.hasNext(); ++to) {
            E newSite = newIt.next();

            if ((to >= model.size()) || !Objects.equals( model.get( to ), newSite )) {
                model.add( to, newSite );
                fireIntervalAdded( this, to, to );
            }
        }

        if ((selectedItem == null) && !model.isEmpty())
            setSelectedItem( model.get( 0 ) );
        else if (!model.contains( selectedItem ))
            setSelectedItem( null );
    }

    @Override
    @SuppressWarnings({ "unchecked", "SuspiciousMethodCalls" })
    public synchronized void setSelectedItem(@Nullable final Object newSelectedItem) {
        if (!Objects.equals( selectedItem, newSelectedItem ) && model.contains( newSelectedItem )) {
            selectedItem = (E) newSelectedItem;
            fireContentsChanged( this, -1, -1 );
        }
    }

    @Nullable
    @Override
    public synchronized E getSelectedItem() {
        return selectedItem;
    }
}
