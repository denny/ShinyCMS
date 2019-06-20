# ===================================================================
# File:		t/schema-results/Feed.t
# Project:	ShinyCMS
# Purpose:	Tests for Feed and FeedItem models
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::More;

use lib 't/support';
require 'login_helpers.pl';  ## no critic


# Get a schema object
my $schema = get_schema();

# Create a feed, put some items in it
my $feed = $schema->resultset( 'Feed' )->create({
	name => 'Fillerama Feed',
	url  => 'http://fillerama.io/',
});

my $item1 = $feed->feed_items->create({
	body => <<EOT
<p>Wow! A superpowers drug you can just rub onto your skin? You'd think it would be something you'd have to freebase. Hey, tell me something. You've got all this money. How come you always dress like you're doing your laundry?
</p>
<p>You guys aren't Santa! You're not even robots. How dare you lie in front of Jesus? Moving along… Does anybody else feel jealous and aroused and worried? Yeah, lots of people did.
</p>
<p>Goodbye, cruel world. Goodbye, cruel lamp. Goodbye, cruel velvet drapes, lined with what would appear to be some sort of cruel muslin and the cute little pom-pom curtain pull cords. Cruel though they may be… You seem malnourished. Are you suffering from intestinal parasites?EOT
</p>
EOT
});
my $item2 = $feed->feed_items->create({
	body => <<EOT
Humans dating robots is sick. You people wonder why I'm still single? It's 'cause all the fine robot sisters are dating humans! I'm just glad my fat, ugly mama isn't alive to see this day. How much did you make me?
<br><br>
Morbo can't understand his teleprompter because he forgot how you say that letter that's shaped like a man wearing a hat. Whoa a real live robot; or is that some kind of cheesy New Year's costume? Kif, I have mated with a woman. Inform the men.
<br><br>
I daresay that Fry has discovered the smelliest object in the known universe! The key to victory is discipline, and that means a well made bed. You will practice until you can make your bed in your sleep.
<br><br>
EOT
});

# Get some teasers
my $newlines = () = $item1->teaser =~ m{\n}gms;
ok(
	$newlines == 2,
	'Default teaser output has one paragraph'
);

$newlines = () = $item1->teaser(3) =~ m{\n}gms;
ok(
	$newlines == 6,
	'->teaser(3) output has three paragraphs'
);

$newlines = () = $item2->teaser(2) =~ m{\n}gms;
ok(
	$newlines == 4,
	'Copes with <br> as well as <p>'
);

done_testing();
