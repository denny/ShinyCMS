# ===================================================================
# File:		database/test_data.sql
# Project:	ShinyCMS
# Purpose:	Test data
# 
# Author:	Denny de la Haye <2010@denny.me>
# Copyright (c) 2009-2010 Shiny Ideas - www.shinyideas.co.uk
# 
# ShinyCMS is free software. You can redistribute it and/or modify it 
# under the terms of the GNU Affero General Public License.
# ===================================================================


# --------------------
# CMS Pages
# --------------------

insert into cms_template values ( 1, 'Homepage',     'homepage.tt'     );
insert into cms_template values ( 2, 'Subpage',      'plain.tt'        );
insert into cms_template values ( 3, 'Contact Form', 'contact-form.tt' );

insert into cms_template_element values ( 1, 1, 'heading1',    'Short Text' );
insert into cms_template_element values ( 2, 1, 'html1',       'HTML'       );
insert into cms_template_element values ( 3, 2, 'heading1',    'Short Text' );
insert into cms_template_element values ( 4, 2, 'paragraphs1', 'Long Text'  );
insert into cms_template_element values ( 5, 2, 'html1',       'HTML'       );
insert into cms_template_element values ( 6, 2, 'image1',      'Image'      );

insert into cms_section values ( 1, 'Main',  'main',  'Main pages',  'home',    1 );
insert into cms_section values ( 2, 'Other', 'other', 'Other pages', 'subpage', 2 );

insert into cms_page values ( 1, 'Home Page',     'home',       1, 1, 1 );
insert into cms_page values ( 2, 'Subpage',       'subpage',    2, 2, 2 );
insert into cms_page values ( 3, 'Upper Subpage', 'upper',      2, 2, 1 );
insert into cms_page values ( 4, 'Contact Us',    'contact-us', 3, 1, 2 );


insert into cms_page_element values (  1, 1, 'heading1',   'Short Text', 'This is a CMS heading' );
insert into cms_page_element values (  2, 1, 'html1',      'HTML',       '<p>This text comes from the database, not the disk.  It is under CMS control.  It is WYSIWYG editable.</p>' );

insert into cms_page_element values (  3, 2, 'heading1',    'Short Text', 'This is another CMS heading' );
insert into cms_page_element values (  4, 2, 'paragraphs1', 'Long Text',  'This is the subpage.  It has different content.  This text can be edited too, but only as text (with paragraph breaks), not as full HTML WYSIWYG content.' );
insert into cms_page_element values (  5, 2, 'html1',       'HTML',       '<p>HTML editor widget is still WYSIWYGy though!</p>' );
insert into cms_page_element values (  6, 2, 'image1',      'Image',      'blue-dog.jpg' );

insert into cms_page_element values (  7, 3, 'heading1',    'Short Text', 'This is the third page' );
insert into cms_page_element values (  8, 3, 'paragraphs1', 'Long Text',  'Although this page was created after subpage, it should be above it in the menus due to its menu_position setting.' );
insert into cms_page_element values (  9, 3, 'html1',       'HTML',       '<p>HTML editor widget remains WYSIWYGy.</p>' );
insert into cms_page_element values ( 10, 3, 'image1',      'Image',      'blue-dog.jpg' );

insert into cms_form values ( 1, 'Contact Form', 'contact', '/pages/main/home', 'Email', '2010@denny.me', null );



# --------------------
# Polls
# --------------------

insert into poll_question values ( 1, 'Question goes where?' );

insert into poll_answer values ( 1, 1, 'Here'  );
insert into poll_answer values ( 2, 1, 'There' );



# --------------------
# Events
# --------------------

insert into event values ( 1, 'Past Event', 'past-event', 'This is the first event, it is in the past.', null, '2010-10-10 18:00', '2010-10-10 20:00', 'EC1V 9AU', null, null, null );
insert into event values ( 2, 'Current Event', 'current-event', 'This is the second event, it is happening today.', null, now(), now(), 'EC1V 9AU', null, null, null );
insert into event values ( 3, 'Christmas', 'xmas', 'Tis the season to be jolly, tra-la-la-la-la, la-la la la.', null, '2010-12-24 16:00', '2010-12-27 10:00', 'EC1V 9AU', null, 'http://shinycms.org', null );



# --------------------
# Shop
# --------------------

insert into shop_category values ( 1, null, 'Widgets', 'widgets', 'This is the widgets section.' );
insert into shop_category values ( 2, null, 'Doodahs', 'doodahs', 'This is the doodahs section.' );
insert into shop_category values ( 3, 1, 'Ambidextrous Widgets', 'ambi-widgets', 'Ambidextrous widgets only.' );


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
insert into shop_item values ( 3, 'green-ambi-widget',  'Green Ambidextrous Widget', 'This green widget swings both ways.  Handy.', 'razer.jpg', 123, null );


insert into shop_item_category values ( 1, 1 );
insert into shop_item_category values ( 2, 1 );
insert into shop_item_category values ( 3, 1 );
insert into shop_item_category values ( 3, 2 );


