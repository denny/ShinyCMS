# ============================================================
# File:		database/test_data.sql
# Project:	ShinyCMS
# Author:	Denny de la Haye <2009@denny.me>
# 
# ShinyCMS is free software. You can redistribute it 
# and/or modify it under the same terms as Perl itself.
# ============================================================

# --------------------
# Tidy up
# --------------------

truncate user_role;
truncate user;

truncate cms_page_element;
truncate cms_template;
truncate cms_page;

truncate shop_item;
truncate shop_category;
truncate shop_item_category;

truncate blog_post;
truncate blog;
truncate discussion;
truncate comment;


# --------------------
# Users
# --------------------

insert into user values ( 1, 'denny', 'a736c6304e69e0a8b22bde9d900204949f0608dd072e9044b008d5e183f00c3cXKLR5haJsl', '2009@denny.me',      'Denny', '2009 at denny dot me', 'Denny', 'de la Haye', 1 );
insert into user values ( 2, 'helen', '36ef4b23752ec2e6355898d56714d64fa11d3e6b9caa7e9c940f53a5836ef5edWZFFgCOBsV', 'helenSP@Msenua.org', 'Helen', 'helenatsenuadotorg',   'Helen', 'Lambert',    1 );
insert into user values ( 3, 'username', 'f9190a9b4c6a9fb80fa5a20bdc6aa704cdefb02628f0859d38b6a8dedfdc2fccA/JrY88R89', '2009@denny.me',      'User',  'user@domain.tld',      'User',  'Name',       0 );


insert into role values ( 1, 'User'               );
insert into role values ( 2, 'User Admin'         );
insert into role values ( 3, 'CMS Page Editor'    );
insert into role values ( 4, 'CMS Page Admin'     );
insert into role values ( 5, 'CMS Template Admin' );
insert into role values ( 6, 'Shop Admin'         );


insert into user_role values ( 1, 1 );
insert into user_role values ( 1, 2 );
insert into user_role values ( 1, 3 );
insert into user_role values ( 1, 4 );
insert into user_role values ( 1, 5 );
insert into user_role values ( 1, 6 );
insert into user_role values ( 2, 1 );
insert into user_role values ( 3, 1 );


# --------------------
# CMS Pages
# --------------------

insert into cms_template values ( 1, 'Plain',  'plain.tt' );
insert into cms_template values ( 2, 'Second', 'plain.tt' );

insert into cms_page values ( 1, 'Home Page', 'home', 1 );

insert into cms_page_element values ( 1, 1, 'heading1',   'This is a CMS heading' );
insert into cms_page_element values ( 2, 1, 'paragraph1', 'This text comes from the database, not the disk.  It is under CMS control.' );


# --------------------
# Shop
# --------------------

insert into shop_category values ( 1, 'Widgets', 'widgets', 'This is the widgets section.' );
insert into shop_category values ( 2, 'Doodahs', 'doodahs', 'This is the doodahs section.' );


insert into shop_item values ( 1, 'blue-lh-widget', 'Blue Left-handed Widget', 'A widget, blue in colour, suitable for left-handed applications.', 'blue-dog.jpg', 314, '<form target="paypal" action="https://www.paypal.com/cgi-bin/webscr" method="post">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="8299526">
<input type="image" src="https://www.paypal.com/en_GB/i/btn/btn_cart_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online.">
<img alt="" border="0" src="https://www.paypal.com/en_GB/i/scr/pixel.gif" width="1" height="1">
</form>' );
insert into shop_item values ( 2, 'red-rh-widget',  'Red Right-handed Widget', 'A widget, red in colour, suitable for right-handed applications.', 'redphanatic.jpg', 272, '<form target="paypal" action="https://www.paypal.com/cgi-bin/webscr" method="post">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="8299566">
<input type="image" src="https://www.paypal.com/en_GB/i/btn/btn_cart_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online.">
<img alt="" border="0" src="https://www.paypal.com/en_GB/i/scr/pixel.gif" width="1" height="1">
</form>' );


insert into shop_item_category values ( 1, 1 );
insert into shop_item_category values ( 2, 1 );


# --------------------
# Blogs
# --------------------

insert into blog values ( 1, 'Geeky Gibbering',   1 );
insert into blog values ( 2, 'Wenchly Wittering', 2 );


insert into discussion values ( 1, 1, 'BlogPost' );


insert into blog_post values ( 1, 1, 'First Post!', "We hold these truths to be self-evident, that all men are created equal, that they are endowed by their Creator with certain unalienable Rights, that among these are Life, Liberty and the pursuit of Happiness. — That to secure these rights, Governments are instituted among Men, deriving their just powers from the consent of the governed, — That whenever any Form of Government becomes destructive of these ends, it is the Right of the People to alter or to abolish it, and to institute new Government, laying its foundation on such principles and organizing its powers in such form, as to them shall seem most likely to effect their Safety and Happiness.", '2009-01-01 01:01:01', 1 );
insert into blog_post values ( 1, 2, 'Hot Grits!!', '',         '2009-02-02 02:02:02', null );
insert into blog_post values ( 1, 3, 'Portman!!!',  '',         '2009-03-03 03:03:03', null );
insert into blog_post values ( 2, 1, 'Mmmm, content!',  '',     '2009-01-02 03:04:05', null );
insert into blog_post values ( 2, 2, 'Hmmm, content?',  '',     '2009-05-04 03:02:01', null );


insert into comment values ( 1, 1, null, 'denny', 'siteuser', null, null, 'First Comment',  "Congress shall make no law respecting an establishment of religion, or prohibiting the free exercise thereof; or abridging the freedom of speech, or of the press; or the right of the people peaceably to assemble, and to petition the Government for a redress of grievances.", now() );
insert into comment values ( 1, 2, null, 'denny', 'siteuser', null, null, 'Second Comment', '', now() );
insert into comment values ( 2, 1, null, 'denny', 'siteuser', null, null, 'Second Thread',  '', now() );
insert into comment values ( 1, 3, 1,    'denny', 'siteuser', null, null, 'First Reply',    '', now() );
insert into comment values ( 1, 4, null, 'denny', 'siteuser', null, null, 'Third, ish',     '', now() );
insert into comment values ( 1, 5, 3,    'denny', 'siteuser', null, null, 'Reply reply',    '', now() );

