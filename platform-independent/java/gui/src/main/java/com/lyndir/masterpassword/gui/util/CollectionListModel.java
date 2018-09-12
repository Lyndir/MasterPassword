package com.lyndir.masterpassword.gui.util;

import static com.google.common.base.Preconditions.*;

import com.google.common.base.Predicates;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;
import com.lyndir.lhunath.opal.system.logging.Logger;
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
public class CollectionListModel<E> extends AbstractListModel<E>
        implements ComboBoxModel<E>, ListSelectionListener, Selectable<E, CollectionListModel<E>> {

    private static final Logger logger = Logger.get( CollectionListModel.class );

    private final List<E>     model = new LinkedList<>();
    @Nullable
    private       JList<E>    list;
    @Nullable
    private       E           selectedItem;
    @Nullable
    private       Consumer<E> selectionConsumer;

    @SafeVarargs
    public CollectionListModel(final E... elements) {
        this( Arrays.asList( elements ) );
    }

    public CollectionListModel(final Collection<? extends E> elements) {
        model.addAll( elements );
        selectedItem = getElementAt( 0 );
        fireIntervalAdded( this, 0, model.size() );
    }

    @Override
    public synchronized int getSize() {
        return model.size();
    }

    @Nullable
    @Override
    public synchronized E getElementAt(final int index) {
        return (index < model.size())? model.get( index ): null;
    }

    /**
     * Replace this model's contents with the objects from the new model collection.
     *
     * This operation will mutate the internal model to reflect the given model.
     * The given model will remain untouched and independent from this object.
     */
    @SuppressWarnings({ "Guava", "AssignmentToForLoopParameter" })
    public synchronized void set(final Iterable<? extends E> elements) {
        ListIterator<E> oldIt = model.listIterator();
        for (int from = 0; oldIt.hasNext(); ++from) {
            int to = Iterables.indexOf( elements, Predicates.equalTo( oldIt.next() ) );

            if (to != from) {
                oldIt.remove();
                fireIntervalRemoved( this, from, from );
                --from;
            }
        }

        int to = 0;
        for (final E newSite : elements) {
            if ((to >= model.size()) || !Objects.equals( model.get( to ), newSite )) {
                model.add( to, newSite );
                fireIntervalAdded( this, to, to );
            }

            ++to;
        }

        if ((selectedItem == null) || !model.contains( selectedItem ))
            selectItem( getElementAt( 0 ) );
    }

    @SafeVarargs
    public final synchronized void set(final E... elements) {
        set( ImmutableList.copyOf( elements ) );
    }

    @Override
    @Deprecated
    @SuppressWarnings("unchecked")
    public synchronized void setSelectedItem(@Nullable final Object/* E */ newSelectedItem) {
        selectItem( (E) newSelectedItem );
    }

    public synchronized CollectionListModel<E> selectItem(@Nullable final E newSelectedItem) {
        if (Objects.equals( selectedItem, newSelectedItem ))
            return this;

        selectedItem = newSelectedItem;

        fireContentsChanged( this, -1, -1 );
        //noinspection ObjectEquality
        if ((list != null) && (list.getModel() == this))
            list.setSelectedValue( selectedItem, true );

        if (selectionConsumer != null)
            selectionConsumer.accept( selectedItem );
        return this;
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

    @Override
    public synchronized CollectionListModel<E> selection(@Nullable final Consumer<E> selectionConsumer) {
        this.selectionConsumer = selectionConsumer;
        if (selectionConsumer != null)
            selectionConsumer.accept( selectedItem );

        return this;
    }

    @Override
    public synchronized CollectionListModel<E> selection(@Nullable final E selectedItem, @Nullable final Consumer<E> selectionConsumer) {
        this.selectionConsumer = null;
        selectItem( selectedItem );

        return selection( selectionConsumer );
    }

    @Override
    public synchronized void valueChanged(final ListSelectionEvent event) {
        //noinspection ObjectEquality
        if (!event.getValueIsAdjusting() && (event.getSource() == list) && (checkNotNull( list ).getModel() == this)) {
            selectedItem = list.getSelectedValue();

            if (selectionConsumer != null)
                selectionConsumer.accept( selectedItem );
        }
    }
}
