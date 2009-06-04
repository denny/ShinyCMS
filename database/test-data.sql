truncate blog_post;
truncate blog;

insert into user values ( 1, 'denny', 'a736c6304e69e0a8b22bde9d900204949f0608dd072e9044b008d5e183f00c3cXKLR5haJsl', '2009@denny.me',   'Denny', '2009 at denny dot me',   'Denny', 'de la Haye', 1 );
insert into user values ( 2, 'helen', '36ef4b23752ec2e6355898d56714d64fa11d3e6b9caa7e9c940f53a5836ef5edWZFFgCOBsV', 'helen@senua.org', 'Helen', 'helen at senua dot org', 'Helen', 'Lambert',    1 );
insert into user values ( 3, 'spork', 'f9190a9b4c6a9fb80fa5a20bdc6aa704cdefb02628f0859d38b6a8dedfdc2fccA/JrY88R89', 'spork@denny.me',  'Spork', 'spork@spork.spork',      'Spork', 'Spork',      0 );

insert into role values ( 1, 'user'  );
insert into role values ( 2, 'admin' );

insert into user_role values ( 1, 1 );
insert into user_role values ( 1, 2 );
insert into user_role values ( 2, 1 );
insert into user_role values ( 3, 1 );

insert into blog values ( 1, 'Geeky Gibbering',   1 );
insert into blog values ( 2, 'Wenchly Wittering', 2 );

insert into blog_post values ( 1, 1, 'First Post!', 'Oh yeah.', '2009-01-01 01:01:01' );
insert into blog_post values ( 2, 1, 'Hot Grits!!', '',         '2009-02-02 02:02:02' );
insert into blog_post values ( 3, 1, 'Portman!!!',  '',         '2009-03-03 03:03:03' );
insert into blog_post values ( 4, 2, 'Mmmm, porn',  '',         '2009-01-02 03:04:05' );
insert into blog_post values ( 5, 2, 'Hmmm, pr0n',  '',         '2009-05-04 03:02:01' );


