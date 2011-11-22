# ===================================================================
# File:		database/schema.sql
# Project:	ShinyCMS
# Purpose:	Database schema
# 
# Author:	Denny de la Haye <2011@denny.me>
# Copyright (c) 2009-2011 Shiny Ideas - www.shinyideas.co.uk
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

drop table if exists comment;
drop table if exists discussion;

drop table if exists shop_item_category;
drop table if exists shop_category;
drop table if exists shop_item;
drop table if exists shop_item_element;
drop table if exists shop_product_type;
drop table if exists shop_product_type_element;

drop table if exists tag;
drop table if exists tagset;

drop table if exists list_recipient;
drop table if exists mail_recipient;
drop table if exists mailing_list;
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
drop table if exists user_role;
drop table if exists role;
drop table if exists user;

set foreign_key_checks = 1;


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
	
	active			int				not null default 1,
	
	unique  key username ( username ),
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
	id				int				not null auto_increment,
	user			int				not null,
	role			int				not null,
	
	foreign key user ( user ) references user ( id ),
	foreign key role ( role ) references role ( id ),
	primary key ( id )
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
	
	foreign key user ( user ) references user ( id ),
	primary key ( user, code )
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
	
	foreign key template_id ( template ) references cms_template ( id ),
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
	
	foreign key default_page_id ( default_page ) references cms_page ( id ),
	unique  key url_name ( url_name ),
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
	
	foreign key template_id  ( template ) references cms_template ( id ),
	foreign key section_id   ( section  ) references cms_section  ( id ),
	unique  key section_page ( section, url_name ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists cms_page_element (
	id				int				not null auto_increment,
	page			int				not null,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',
	content			text			,
	
	foreign key page_id ( page ) references cms_page ( id ),
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
	
	unique  key url_name ( url_name ),
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
	
	foreign key list_id      ( list      ) references mailing_list   ( id ),
	foreign key recipient_id ( recipient ) references mail_recipient ( id ),
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
	
	foreign key template_id ( template ) references newsletter_template ( id ),
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
	sent			datetime		,
	
	foreign key template_id ( template ) references newsletter_template ( id ),
	foreign key list_id     ( list     ) references mailing_list        ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists newsletter_element (
	id				int				not null auto_increment,
	newsletter		int				not null,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',
	content			text			,
	
	foreign key newsletter_id ( newsletter ) references newsletter ( id ),
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Comments
# --------------------

create table if not exists discussion (
	id				int				not null auto_increment,
	resource_id		int				not null,
	resource_type	varchar(50)		not null,
	
	primary key ( id )
)
ENGINE=InnoDB;


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
	
#	unique key discussion_comment ( discussion, id );
	foreign key discussion_id ( discussion ) references discussion ( id ),
	foreign key user_id       ( author     ) references user       ( id ),
	primary key ( uid )
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
	posted			timestamp		not null default current_timestamp,
	
	foreign key author_id ( author ) references user ( id ),
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
	
	foreign key user_id ( author ) references user ( id ),
	foreign key discussion_id ( discussion ) references discussion ( id ),
	foreign key blog_id ( blog ) references blog ( id ),
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
	
	foreign key section_id ( section ) references forum_section ( id ),
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
	commented_on	datetime		not null default '1900-01-01',
	
	discussion		int				,
	
	foreign key user_id ( author ) references user ( id ),
	foreign key discussion_id ( discussion ) references discussion ( id ),
	foreign key forum_id ( forum ) references forum ( id ),
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
	
	foreign key question_id ( question ) references poll_question ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists poll_user_vote (
	id				int				not null auto_increment,
	question		int				not null,
	answer			int				not null,
	user			int				not null,
	ip_address		varchar(15)		not null,
	
	foreign key question_id ( question ) references poll_question ( id ),
	foreign key answer_id ( answer ) references poll_answer ( id ),
	foreign key user_id ( user ) references user ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists poll_anon_vote (
	id				int				not null auto_increment,
	question		int				not null,
	answer			int				not null,
	ip_address		varchar(15)		not null,
	
	foreign key question_id ( question ) references poll_question ( id ),
	foreign key answer_id ( answer ) references poll_answer ( id ),
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
	
	start_date		datetime		not null,
	end_date		datetime		not null,
	
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
	
	foreign key tagset_id ( tagset ) references tagset ( id ),
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
	posted			datetime		,
	
	foreign key feed_id ( feed ) references feed ( id ),
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
	
	foreign key product_type_id ( product_type ) references shop_product_type ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_category (
	id				int				not null auto_increment,
	parent			int				,
	name			varchar(100)	not null,
	url_name		varchar(100)	not null,
	description		text			,
	
	foreign key parent_id ( parent ) references shop_category ( id ),
	unique  key url_name ( url_name ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_item (
	id				int				not null auto_increment,
	product_type	int				not null,
	name			varchar(200)	,
	code			varchar(100)	,
	description		text			,
	image			varchar(200)	,
	price			decimal(9,2)	not null default '0.00',
	
	added			timestamp		not null default current_timestamp,
	updated			datetime		,
	
	hidden			boolean			default false,
	
	discussion		int				,
	
	foreign key product_type_id ( product_type ) references shop_product_type ( id ),
	foreign key discussion_id ( discussion ) references discussion ( id ),
	unique  key product_code ( code ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_item_element (
	id				int				not null auto_increment,
	item			int				not null,
	name			varchar(50)		not null,
	type			varchar(20)		not null default 'Short Text',
	content			text			,
	
	foreign key item_id ( item ) references shop_item ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_item_category (
	item			int				not null,
	category		int				not null,
	
	foreign key item_id     ( item     ) references shop_item     ( id ),
	foreign key category_id ( category ) references shop_category ( id ),
	primary key ( item, category )
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
	
	foreign key comment_id ( comment ) references comment ( uid ),
	foreign key user_id ( user ) references user ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists shop_item_like (
	id				int				not null auto_increment,
	
	item			int				not null,
	user			int				,
	ip_address		varchar(15)		not null,
	
	foreign key item_id ( item ) references shop_item ( id ),
	foreign key user_id ( user ) references user ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


