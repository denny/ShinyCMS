# ===================================================================
# File:		database/schema.sql
# Project:	ShinyCMS
# Purpose:	Database schema
# 
# Author:	Denny de la Haye <2010@denny.me>
# Copyright (c) 2009-2010 Shiny Ideas - www.shinyideas.co.uk
# 
# ShinyCMS is free software. You can redistribute it and/or modify it 
# under the terms of the GNU Affero General Public License.
# ===================================================================

# --------------------
# Tidy up
# --------------------

drop table if exists blog_post;
drop table if exists blog;

drop table if exists comment;
drop table if exists discussion;

drop table if exists shop_item_category;
drop table if exists shop_category;
drop table if exists shop_item;

drop table if exists gallery;
drop table if exists image;

drop table if exists cms_page_element;
drop table if exists cms_page;
drop table if exists cms_template;

drop table if exists user_role;
drop table if exists role;
drop table if exists user;



# --------------------
# Users
# --------------------

create table if not exists user (
	id				int				not null auto_increment,
	username		varchar(50)		not null,
	password		varchar(200)	not null,
	email			varchar(200)	not null,
	
	display_name	varchar(50)		,
	display_email	varchar(200)	,
	
	firstname		varchar(50)		,
	surname			varchar(50)		,

	active			int				not null default 1,
	
	unique  key username ( username ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists role (
	id				int				not null auto_increment,
	role			text			,
	
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists user_role (
	user			int				not null auto_increment,
	role			int				,
	
	foreign key user ( user ) references user ( id ),
	foreign key role ( role ) references role ( id ),
	primary key ( user, role )
)
ENGINE=InnoDB;



# --------------------
# CMS
# --------------------

create table if not exists cms_template (
	id				int				not null auto_increment,
	name			varchar(100)	,
	filename		varchar(100)	,
	
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists cms_page (
	id				int				not null auto_increment,
	name			varchar(100)	not null,
	url_name		varchar(100)	not null,
	template		int				not null,
	
	foreign key template_id ( template ) references cms_template ( id ),
	unique  key url_name ( url_name ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists cms_page_element (
	id				int				not null auto_increment,
	page			int				not null,
	name			varchar(50)		not null,
	type			varchar(10)		not null default 'Text',
	content			text			,
	
	foreign key page_id ( page ) references cms_page ( id ),
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
	uploaded		datetime		not null,
	path			text			not null,
	caption			text			,
	
	primary key ( id )
)
ENGINE=InnoDB;



# --------------------
# Shop
# --------------------

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
	code			varchar(100)	,
	name			varchar(200)	,
	description		text			,
	image			varchar(200)	,
	price			decimal(9,2)	not null default '0.00',
	
	paypal_button	text			,
	
	unique  key product_code ( code ),
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
# Comments
# --------------------

create table if not exists discussion (
	id				int				not null auto_increment,
	resource_id		int				not null,
	resource_type	varchar(50)		not null default 'BlogPost',
	
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists comment (
	discussion		int				not null,
	id				int				not null,
	parent			int				,
	
	author_name		varchar(100)	not null,
	author_type		varchar(20)		not null,	# siteuser, openid, unverified, anon
	author_email	varchar(200)	,
	author_link		varchar(200)	,
	
	title			varchar(100)	not null,
	body			text			not null,
	posted			datetime		not null,
	
	primary key ( discussion, id )
)
ENGINE=InnoDB;



# --------------------
# Blogs
# --------------------

create table if not exists blog (
	id				int				not null auto_increment,
	title			varchar(100)	not null,
	author			int				not null,
	
	foreign key user_id ( author ) references user ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists blog_post (
	blog			int				not null,
	id				int				not null,
	title			varchar(100)	not null,
	body			text			not null,
	posted			datetime		not null,
	
	discussion		int				,
	
	foreign key discussion_id ( discussion ) references discussion ( id ),
	foreign key blog_id ( blog ) references blog ( id ),
	primary key ( blog, id )
)
ENGINE=InnoDB;


