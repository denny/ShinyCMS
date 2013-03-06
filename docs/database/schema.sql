# ===================================================================
# File:		database/schema.sql
# Project:	ShinyCMS
# Purpose:	Database schema
#
# Author:	Denny de la Haye <2013@denny.me>
# Copyright (c) 2009-2013 Shiny Ideas - www.shinyideas.co.uk
#
# ShinyCMS is free software. You can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License.
# ===================================================================

# --------------------
# Tidy up
# --------------------

set foreign_key_checks = 0;

drop table if exists gallery;
drop table if exists image;

drop table if exists event;

drop table if exists feed_item;
drop table if exists feed;

drop table if exists comment_like;
drop table if exists shop_item_like;

drop table if exists comment;
drop table if exists discussion;

drop table if exists ccbill_log;

drop table if exists shop_item_category;
drop table if exists shop_category;
drop table if exists shop_item;
drop table if exists shop_item_element;
drop table if exists shop_product_type;
drop table if exists shop_product_type_element;
drop table if exists postage_option;
drop table if exists shop_item_postage_option;
drop table if exists basket;
drop table if exists basket_item;
drop table if exists basket_item_attribute;
drop table if exists `order`;
drop table if exists order_item;
drop table if exists order_item_attribute;

drop table if exists poll_anon_vote;
drop table if exists poll_user_vote;
drop table if exists poll_answer;
drop table if exists poll_question;

drop table if exists forum_post;
drop table if exists forum;
drop table if exists forum_section;

drop table if exists blog_post;
drop table if exists blog;

drop table if exists news_item;

drop table if exists tag;
drop table if exists tagset;

drop table if exists list_recipient;
drop table if exists mail_recipient;drop table if exists mailing_list;
drop table if exists newsletter_element;
drop table if exists newsletter;
drop table if exists newsletter_template_element;
drop table if exists newsletter_template;

drop table if exists shared_content;

drop table if exists cms_form;
drop table if exists cms_page_element;
drop table if exists cms_page;
drop table if exists cms_section;
drop table if exists cms_template_element;
drop table if exists cms_template;

drop table if exists confirmation;
drop table if exists session;
drop table if exists user_access;
drop table if exists access;
drop table if exists user_role;
drop table if exists role;
drop table if exists user;

set foreign_key_checks = 1;



# --------------------
# Discussions
# --------------------

create table if not exists discussion (
	id				int				not null auto_increment,
	resource_id		int				not null,
	resource_type	varchar(50)		not null,

	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Users
# --------------------

create table if not exists user (
	id				int				not null auto_increment,
	username		varchar(50)		not null,
	password		varchar(74)		not null,
	email			varchar(200)	not null,

	firstname		varchar(50)		,
	surname			varchar(50)		,

	display_name	varchar(100)	,
	display_email	varchar(200)	,

	website			varchar(200)	,
	profile_pic		varchar(100)	,
	bio				text			,

	location		varchar(100)	,
	postcode		varchar(10)		,

	admin_notes		text			,

	discussion		int				,

	active			int				not null default 1,

	unique  key user_username   ( username ),
	foreign key user_discussion ( discussion ) references discussion ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists role (
	id				int				not null auto_increment,
	role			varchar(50)		not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists user_role (
	user			int				not null,
	role			int				not null,

	foreign key user_role_user ( user ) references user ( id ),
	foreign key user_role_role ( role ) references role ( id ),
	primary key ( user, role )
)
ENGINE=InnoDB;


create table if not exists access (
	id				int				not null auto_increment,
	access			varchar(50)		not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists user_access (
	user			int				not null,
	access			int				not null,
	expires			datetime		,

	foreign key user_access_user   ( user   ) references user   ( id ),
	foreign key user_access_access ( access ) references access ( id ),
	primary key ( user, access )
)
ENGINE=InnoDB;


create table if not exists session (
	id				char(72)		,
	session_data	text			,
	expires			int				,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists confirmation (
	user			int				not null,
	code			varchar(32)		not null,
	created			timestamp		not null default current_timestamp,

	foreign key confirmation_user ( user ) references user ( id ),
	primary key ( user, code )
)
ENGINE=InnoDB;



# --------------------
# Comments
# --------------------

create table if not exists comment (
	uid				int				not null auto_increment,

	discussion		int				not null,
	id				int				not null,
	parent			int				,

	author			int				,			-- User ID if 'Site User'
	author_type		varchar(20)		not null,	-- Site User, OpenID, Unverified, Anonymous
	author_name		varchar(100)	,
	author_email	varchar(200)	,
	author_link		varchar(200)	,

	title			varchar(100)	,
	body			text			,
	posted			timestamp		not null default current_timestamp,

	hidden			varchar(3)		,

#	unique  key discussion_comment ( discussion, id );
	foreign key comment_discussion ( discussion ) references discussion ( id ),
	foreign key comment_user       ( author     ) references user       ( id ),
	primary key ( uid )
)
ENGINE=InnoDB;



# --------------------
# CMS Pages
# --------------------

set foreign_key_checks = 0;

create table if not exists cms_template (
	id				int				not null auto_increment,
	name			varchar(100)	not null,
	template_file	varchar(100)	not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists cms_template_element (
	id				int				not null auto_increment,
	template		int				not null,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',

	foreign key cms_template_element_template ( template ) references cms_template ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists cms_section (
	id				int				not null auto_increment,
	name			varchar(100)	not null,
	url_name		varchar(100)	not null,
	description		text			,
	default_page	int				,
	menu_position	int				,

	unique  key cms_section_url_name ( url_name ),
	foreign key cms_section_default_page ( default_page ) references cms_page ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists cms_page (
	id				int				not null auto_increment,
	name			varchar(100)	not null,
	url_name		varchar(100)	not null,
	template		int				not null,
	section			int				,
	menu_position	int				,

	unique  key cms_page_url_name ( section, url_name ),
	foreign key cms_page_template ( template ) references cms_template ( id ),
	foreign key cms_page_section  ( section  ) references cms_section  ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists cms_page_element (
	id				int				not null auto_increment,
	page			int				not null,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',
	content			text			,

	foreign key cms_page_element_page ( page ) references cms_page ( id ),
	primary key ( id )
)
ENGINE=InnoDB;

set foreign_key_checks = 1;



# --------------------
# CMS Forms
# --------------------

create table if not exists cms_form (
	id				int				not null auto_increment,
	name			varchar(100)	not null,
	url_name		varchar(100)	not null,
	redirect		varchar(200)	,
	action			varchar(20)		not null,	# Email / ?
	email_to		varchar(100)	,			# Email address for recipient
	template		varchar(100)	,			# Template for email, if any

	unique  key cms_form_url_name ( url_name ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Shared Content
# --------------------

create table if not exists shared_content (
	id				int				not null auto_increment,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',
	content			text			,

	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Newsletters
# --------------------

create table if not exists mailing_list (
	id				int				not null auto_increment,
	name			varchar(100)	,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists mail_recipient (
	id				int				not null auto_increment,
	name			varchar(100)	,
	email			varchar(200)	not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists list_recipient (
	id				int				not null auto_increment,
	list			int				not null,
	recipient		int				not null,

	foreign key list_recipient_list      ( list      ) references mailing_list   ( id ),
	foreign key list_recipient_recipient ( recipient ) references mail_recipient ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists newsletter_template (
	id				int				not null auto_increment,
	name			varchar(100)	not null,
	filename		varchar(100)	not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists newsletter_template_element (
	id				int				not null auto_increment,
	template		int				not null,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',

	foreign key newsletter_template_element_template ( template ) references newsletter_template ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists newsletter (
	id				int				not null auto_increment,
	title			varchar(100)	not null,
	url_title		varchar(100)	not null,
	template		int				not null,
	plaintext		text			,
	list			int				not null,
	status			varchar(20)		not null default 'Not sent',
	sent			timestamp		,

	foreign key newsletter_template ( template ) references newsletter_template ( id ),
	foreign key newsletter_list     ( list     ) references mailing_list        ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists newsletter_element (
	id				int				not null auto_increment,
	newsletter		int				not null,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',
	content			text			,

	foreign key newsletter_element_newsletter ( newsletter ) references newsletter ( id ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# News
# --------------------

create table if not exists news_item (
	id				int				not null auto_increment,
	author			int				not null,

	title			varchar(100)	not null,
	url_title		varchar(100)	not null,
	body			text			not null,
	related_url		varchar(255)	,
	posted			timestamp		not null default current_timestamp,

	foreign key news_item_author ( author ) references user ( id ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Blogs
# --------------------

create table if not exists blog (
	id				int				not null auto_increment,
	title			varchar(100)	not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists blog_post (
	id				int				not null auto_increment,
	title			varchar(100)	not null,
	url_title		varchar(100)	not null,
	body			text			not null,
	author			int				,
	blog			int				not null,
	posted			timestamp		not null default current_timestamp,

	discussion		int				,

	foreign key blog_post_author     ( author     ) references user       ( id ),
	foreign key blog_post_blog       ( blog       ) references blog       ( id ),
	foreign key blog_post_discussion ( discussion ) references discussion ( id ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Forums
# --------------------

create table if not exists forum_section (
	id				int				not null auto_increment,

	name			varchar(100)	not null,
	url_name		varchar(100)	not null,
	description		text			,
	display_order	int				,

	unique  key forum_section_url_name ( url_name ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists forum (
	id				int				not null auto_increment,
	section			int				not null,

	name			varchar(100)	not null,
	url_name		varchar(100)	not null,
	description		text			,
	display_order	int				,

	unique  key forum_url_name ( section, url_name ),
	foreign key forum_section ( section ) references forum_section ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists forum_post (
	id				int				not null auto_increment,
	forum			int				not null,

	title			varchar(100)	not null,
	url_title		varchar(100)	not null,
	body			text			not null,
	author			int				,
	posted			timestamp		not null default current_timestamp,
	display_order	int				,
	commented_on	timestamp		not null default '1971-01-01 00:00:00',

	discussion		int				,

	foreign key forum_post_forum      ( forum      ) references forum      ( id ),
	foreign key forum_post_author     ( author     ) references user       ( id ),
	foreign key forum_post_discussion ( discussion ) references discussion ( id ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Polls
# --------------------

create table if not exists poll_question (
	id				int				not null auto_increment,
	question		varchar(100)	not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists poll_answer (
	id				int				not null auto_increment,
	question		int				not null,
	answer			varchar(100)	not null,

	foreign key poll_answer_question ( question ) references poll_question ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists poll_user_vote (
	id				int				not null auto_increment,
	question		int				not null,
	answer			int				not null,
	user			int				not null,
	ip_address		varchar(15)		not null,

	foreign key poll_user_vote_question ( question ) references poll_question ( id ),
	foreign key poll_user_vote_answer   ( answer   ) references poll_answer   ( id ),
	foreign key poll_user_vote_user     ( user     ) references user          ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists poll_anon_vote (
	id				int				not null auto_increment,
	question		int				not null,
	answer			int				not null,
	ip_address		varchar(15)		not null,

	foreign key poll_anon_vote_question ( question ) references poll_question ( id ),
	foreign key poll_anon_vote_answer   ( answer   ) references poll_answer   ( id ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Events
# --------------------

create table if not exists event (
	id				int				not null auto_increment,
	name			varchar(100)	not null,
	url_name		varchar(100)	not null,
	description		text			,
	image			varchar(100)	,

	start_date		timestamp		not null default '1971-01-01 01:01:01',
	end_date		timestamp		not null default '1971-01-01 01:01:01',

	postcode		varchar(10)		,
	email			varchar(200)	,
	link			varchar(200)	,
	booking_link	varchar(200)	,

	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Tags
# --------------------

create table if not exists tagset (
	id				int				not null auto_increment,

	resource_id		int				not null,
	resource_type	varchar(50)		not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists tag (
	tag				varchar(50)		not null,
	tagset			int				not null,

	foreign key tag_tagset ( tagset ) references tagset ( id ),
	primary key ( tag, tagset )
)
ENGINE=InnoDB;



# --------------------
# Feeds
# --------------------

create table if not exists feed (
	id				int				not null auto_increment,

	name			varchar(100)	not null,
	url				varchar(255)	not null,

	last_checked	timestamp		not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists feed_item (
	id				int				not null auto_increment,
	feed			int				not null,

	url				varchar(255)	,
	title			varchar(100)	,
	body			text			,
	posted			timestamp		,

	foreign key feed_item_feed ( feed ) references feed ( id ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Shop
# --------------------

create table if not exists shop_product_type (
	id				int				not null auto_increment,
	name			varchar(100)	not null,
	template_file	varchar(100)	not null,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_product_type_element (
	id				int				not null auto_increment,
	product_type	int				not null,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',

	foreign key shop_product_type_element_product_type ( product_type ) references shop_product_type ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_category (
	id				int				not null auto_increment,
	parent			int				,
	name			varchar(100)	not null,
	url_name		varchar(100)	not null,
	description		text			,

	unique  key shop_category_url_name ( url_name ),
	foreign key shop_category_parent   ( parent   ) references shop_category ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_item (
	id				int				not null auto_increment,
	product_type	int				not null,
	name			varchar(200)	not null,
	code			varchar(100)	not null,
	description		text			,
	image			varchar(200)	,
	price			decimal(9,2)	,

	stock			int				,
	restock_date	datetime		,

	added			timestamp		not null default current_timestamp,
#	updated			timestamp		null default null,
	updated			datetime		,

	hidden			boolean			default false,

	discussion		int				,

	unique  key shop_item_product_code ( code ),
	foreign key shop_item_product_type ( product_type ) references shop_product_type ( id ),
	foreign key shop_item_discussion   ( discussion   ) references discussion ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_item_element (
	id				int				not null auto_increment,
	item			int				not null,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',
	content			text			,

	foreign key shop_item_element_item ( item ) references shop_item ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_item_category (
	item			int				not null,
	category		int				not null,

	foreign key shop_item_category_item     ( item     ) references shop_item     ( id ),
	foreign key shop_item_category_category ( category ) references shop_category ( id ),
	primary key ( item, category )
)
ENGINE=InnoDB;


create table if not exists postage_option (
	id				int				not null auto_increment,
	name			varchar(50)		not null,
	price			decimal(9,2)	not null default '0.00',
	description		text			,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_item_postage_option (
	item			int				not null,
	postage			int				not null,

	foreign key shop_item_postage_item    ( item    ) references shop_item      ( id ),
	foreign key shop_item_postage_postage ( postage ) references postage_option ( id ),
	primary key ( item, postage )
)
ENGINE=InnoDB;


create table if not exists basket (
	id				int				not null auto_increment,

	session			char(72)		,
	user			int				,

	foreign key basket_session ( session ) references session ( id ),
	foreign key basket_user    ( user    ) references user    ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists basket_item (
	id				int				not null auto_increment,
	basket			int				not null,
	item			int				not null,

	quantity		int				not null default 1,
	unit_price		decimal(9,2)	not null default '0.00',

	foreign key basket_item_basket ( basket ) references basket    ( id ),
	foreign key basket_item_item   ( item   ) references shop_item ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists basket_item_attribute (
	id				int				not null auto_increment,
	item			int				not null,
	
	name			varchar(100)	not null,
	value			text			not null,
	
	foreign key basket_item_attribute_item ( item ) references basket_item ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists `order` (
	id						int				not null auto_increment,

	session					char(72)		,
	user					int				,

	billing_address			text			not null,
	billing_town			varchar(100)	not null,
	billing_county			varchar(50)		,
	billing_country			varchar(50)		not null,
	billing_postcode		varchar(10)		not null,

	delivery_address		text			,
	delivery_town			varchar(100)	,
	delivery_county			varchar(50)		,
	delivery_country		varchar(50)		,
	delivery_postcode		varchar(10)		,

	status					varchar(50)		not null default 'Checkout incomplete',
	created					datetime		not null,
	updated					datetime		,

	foreign key order_session ( session ) references session ( id ),
	foreign key order_user    ( user    ) references user    ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists order_item (
	id				int				not null auto_increment,
	`order`			int				not null,
	item			int				not null,

	quantity		int				not null default 1,
	unit_price		decimal(9,2)	not null default '0.00',
	postage			int				,

	foreign key order_item_order   ( `order` ) references `order`        ( id ),
	foreign key order_item_item    ( item    ) references shop_item      ( id ),
	foreign key order_item_postage ( postage ) references postage_option ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists order_item_attribute (
	id				int				not null auto_increment,
	item			int				not null,
	
	name			varchar(100)	not null,
	value			text			not null,
	
	foreign key order_item_attribute_item ( item ) references order_item ( id ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# CCBill transaction log
# --------------------

create table if not exists ccbill_log (
	id				int				not null auto_increment,

	logged			timestamp		not null default current_timestamp,
	status			varchar(20)		not null,
	notes			text			,

	user			int				,

	foreign key ccbill_log_user ( user ) references user ( id ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Image Galleries
# --------------------

create table if not exists gallery (
	id				int				not null auto_increment,

	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists image (
	id				int				not null auto_increment,

	name			varchar(200)	not null,
	mime			varchar(200)	not null,
	uploaded		timestamp		not null default current_timestamp,
	path			text			not null,
	caption			text			,

	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Likes
# --------------------

create table if not exists comment_like (
	id				int				not null auto_increment,

	comment			int				not null,
	user			int				,
	ip_address		varchar(15)		not null,

	foreign key comment_like_comment ( comment ) references comment ( uid ),
	foreign key comment_like_user    ( user    ) references user    ( id  ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_item_like (
	id				int				not null auto_increment,

	item			int				not null,
	user			int				,
	ip_address		varchar(15)		not null,

	foreign key shop_item_like_item ( item ) references shop_item ( id ),
	foreign key shop_item_like_user ( user ) references user      ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


