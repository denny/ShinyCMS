drop table if exists comment;
drop table if exists blog_post_discussion;
drop table if exists blog_post;
drop table if exists blog;
drop table if exists user_role;
drop table if exists role;
drop table if exists user;


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
	
	unique key username ( username ),
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


create table if not exists blog (
	id				int				not null auto_increment,
	title			varchar(100)	not null,
	author			int				not null,
	
	foreign key user_id ( author ) references user ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists blog_post (
	id				int				not null auto_increment,
	blog			int				not null,
	title			varchar(100)	not null,
	body			text			not null,
	posted			datetime		not null,
	
	foreign key blog_id ( blog ) references blog ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists discussion (
	id				int				not null auto_increment,
	resource_id		int				not null,
	resource_type	varchar(50)		not null default 'BlogPost',
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists blog_post_discussion (
	id				int				not null auto_increment,
	blog_post		int				not null,
	
	foreign key blog_post_id ( blog_post ) references blog_post ( id ),
	primary key ( id )
)
ENGINE=InnoDB;


create table if not exists comment (
	id				int				not null auto_increment,
	parent			int				,
	discussion		int				not null,
	
	author_name		varchar(100)	not null,
	author_type		varchar(20)		not null,	# siteuser, openid, unverified, anon
	author_email	varchar(200)	,
	author_link		varchar(200)	,
	
	title			varchar(100)	not null,
	body			text			not null,
	posted			datetime		not null,
	
	primary key ( id )
)
ENGINE=InnoDB;


