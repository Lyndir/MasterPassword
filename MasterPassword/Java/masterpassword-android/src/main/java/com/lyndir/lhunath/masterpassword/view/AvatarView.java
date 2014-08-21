package com.lyndir.lhunath.masterpassword.view;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.TextView;
import butterknife.ButterKnife;
import com.lyndir.lhunath.masterpassword.R;
import com.lyndir.lhunath.masterpassword.model.User;


/**
 * @author lhunath, 2014-08-20
 */
public class AvatarView extends FrameLayout {

    private final TextView userName;

    public AvatarView(final Context context) {
        super( context );

        addView( userName = (TextView) LayoutInflater.from( context ).inflate( R.layout.view_user_avatar, this, false ) );
    }

    public void setUser(User user) {
        userName.setText( user.getName() );
        userName.setCompoundDrawables( null, getResources().getDrawable( user.getAvatar().getImageResource() ), null, null );
    }
}
