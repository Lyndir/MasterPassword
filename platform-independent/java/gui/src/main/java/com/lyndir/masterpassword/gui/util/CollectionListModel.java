package com.lyndir.masterpassword.gui.util;

import com.google.common.collect.ImmutableList;
import java.util.*;
import java.util.function.Consumer;
import javax.annotation.Nullable;
import javax.swing.*;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;


/**
 * @author lhunath, 2018-07-19
 */
@SuppressWarnings("serial")
public class CollectionListModel<E> extends AbstractListModel<E> implements ComboBoxModel<E>, ListSelectionListener {

    private final List<E>     model = new LinkedList<>();
    @Nullable
    private       E           selectedItem;
    private       JList<E>    list;
    @Nullable
    private       Consumer<E> selectionConsumer;

    @SafeVarargs
    public static <E> CollectionListModel<E> copy(final E... elements) {
        return copy( Arrays.asList( elements ) );
    }

    public static <E> CollectionListModel<E> copy(final Collection<? extends E> elements) {
        CollectionListModel<E> model = new CollectionListModel<>();
        synchronized (model) {
            model.model.addAll( elements );
            model.selectedItem = model.getElementAt( 0 );
            model.fireIntervalAdded( model, 0, model.model.size() );

            return model;
        }
    }

    @Override
    public synchronized int getSize() {
        return model.size();
    }

    @Override
    @Nullable
    public synchronized E getElementAt(final int index) {
        return (index < model.size())? model.get( index ): null;
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

        if ((selectedItem == null) || !model.contains( selectedItem ))
            setSelectedItem( getElementAt( 0 ) );
    }

    @Override
    @SuppressWarnings({ "unchecked", "SuspiciousMethodCalls" })
    public synchronized void setSelectedItem(@Nullable final Object newSelectedItem) {
        if (!Objects.equals( selectedItem, newSelectedItem ) && model.contains( newSelectedItem )) {
            selectedItem = (E) newSelectedItem;

            fireContentsChanged( this, -1, -1 );
            //noinspection ObjectEquality
            if ((list != null) && (list.getModel() == this))
                list.setSelectedValue( selectedItem, true );

            if (selectionConsumer != null)
                selectionConsumer.accept( selectedItem );
        }
    }

    @Nullable
    @Override
    public synchronized E getSelectedItem() {
        return selectedItem;
    }

    public synchronized void registerList(final JList<E> list) {
        // TODO: This class should probably implement ListSelectionModel instead.
        if (this.list != null)
            this.list.removeListSelectionListener( this );

        this.list = list;
        this.list.addListSelectionListener( this );
        this.list.setModel( this );
    }

    public synchronized CollectionListModel<E> selection(@Nullable final Consumer<E> selectionConsumer) {
        this.selectionConsumer = selectionConsumer;
        if (selectionConsumer != null)
            selectionConsumer.accept( selectedItem );

        return this;
    }

    public synchronized CollectionListModel<E> selection(@Nullable final E selectedItem, @Nullable final Consumer<E> selectionConsumer) {
        this.selectionConsumer = null;
        setSelectedItem( selectedItem );

        return selection( selectionConsumer );
    }

    @Override
    public synchronized void valueChanged(final ListSelectionEvent event) {
        //noinspection ObjectEquality
        if ((event.getSource() == list) && (list.getModel() == this))
            selectedItem = list.getSelectedValue();
    }
}
