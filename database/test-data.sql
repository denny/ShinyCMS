truncate user_role;
truncate user;
truncate blog_post;
truncate blog;
truncate discussion;
truncate comment;


insert into user values ( 1, 'denny', 'a736c6304e69e0a8b22bde9d900204949f0608dd072e9044b008d5e183f00c3cXKLR5haJsl', 'reactant.2009@contentmanaged.org',   'Denny', '2009 at denny dot me',   'Denny', 'de la Haye', 1 );
insert into user values ( 2, 'helen', '36ef4b23752ec2e6355898d56714d64fa11d3e6b9caa7e9c940f53a5836ef5edWZFFgCOBsV', 'helen@senua.spam', 'Helen', 'helen at senua dot org', 'Helen', 'Lambert',    1 );
insert into user values ( 3, 'spork', 'f9190a9b4c6a9fb80fa5a20bdc6aa704cdefb02628f0859d38b6a8dedfdc2fccA/JrY88R89', 'spork@denny.me',  'Spork', 'spork@spork.spork',      'Spork', 'Spork',      0 );


insert into role values ( 1, 'user'  );
insert into role values ( 2, 'admin' );


insert into user_role values ( 1, 1 );
insert into user_role values ( 1, 2 );
insert into user_role values ( 2, 1 );
insert into user_role values ( 3, 1 );


insert into blog values ( 1, 'Geeky Gibbering',   1 );
insert into blog values ( 2, 'Wenchly Wittering', 2 );


insert into discussion values ( 1, 1, 'BlogPost' );


insert into blog_post values ( 1, 1, 'First Post!', "We hold these truths to be self-evident, that all men are created equal, that they are endowed by their Creator with certain unalienable Rights, that among these are Life, Liberty and the pursuit of Happiness. — That to secure these rights, Governments are instituted among Men, deriving their just powers from the consent of the governed, — That whenever any Form of Government becomes destructive of these ends, it is the Right of the People to alter or to abolish it, and to institute new Government, laying its foundation on such principles and organizing its powers in such form, as to them shall seem most likely to effect their Safety and Happiness.", '2009-01-01 01:01:01', 1 );
insert into blog_post values ( 2, 1, 'Hot Grits!!', '',         '2009-02-02 02:02:02', null );
insert into blog_post values ( 3, 1, 'Portman!!!',  '',         '2009-03-03 03:03:03', null );
insert into blog_post values ( 4, 2, 'Mmmm, content!',  '',     '2009-01-02 03:04:05', null );
insert into blog_post values ( 5, 2, 'Hmmm, c0ntent?',  '',     '2009-05-04 03:02:01', null );


insert into comment values ( 1, 1, null, 'denny', 'siteuser', null, null, 'First Comment',  "Congress shall make no law respecting an establishment of religion, or prohibiting the free exercise thereof; or abridging the freedom of speech, or of the press; or the right of the people peaceably to assemble, and to petition the Government for a redress of grievances.", now() );
insert into comment values ( 1, 2, null, 'denny', 'siteuser', null, null, 'Second Comment', '', now() );
insert into comment values ( 2, 1, null, 'denny', 'siteuser', null, null, 'Second Thread',  '', now() );
insert into comment values ( 1, 3, 1,    'denny', 'siteuser', null, null, 'First Reply',    '', now() );
insert into comment values ( 1, 4, null, 'denny', 'siteuser', null, null, 'Third, ish',     '', now() );
insert into comment values ( 1, 5, 3,    'denny', 'siteuser', null, null, 'Reply reply',    '', now() );

