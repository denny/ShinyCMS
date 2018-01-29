FROM debian:jessie
MAINTAINER Denny de la Haye <2018@denny.me>


# Set some general config stuff

ENV APP_NAME=ShinyCMS  \
	APP_PORT=6174       \
	APP_USER=shinycms    \
	APP_DIR=/opt/shinycms \
	SHINYCMS_CONFIG=/opt/shinycms/config/shinycms.conf


# Install required Debian packages

RUN apt-get update \
\
	&& apt-get install -y     \
		cpanminus             \
		gcc                   \
		libexpat-dev          `# Required by XML::Parser for XML::Feed` \
		libmysqlclient-dev    `# Required by DBD::mysql`                \
		libpq-dev             `# Required by DBD::Pg`                   \
		libxml2-dev           `# Required by XML::LibXML for XML::Feed` \
		make                  \
		zlib1g-dev            `# Required by XML::LibXML for XML::Feed` \
\
	&& apt-get clean \
\
	&& rm -rf /var/cache/apt/archives/*


# Install required CPAN modules

RUN cpanm --notest               \
	parent                       \
	Captcha::reCAPTCHA           \
	Catalyst::Action::RenderView \
	Catalyst::Authentication::Realm::SimpleDB  \
	Catalyst::Plugin::Authentication           \
	Catalyst::Plugin::ConfigLoader             \
	Catalyst::Plugin::Session                  \
	Catalyst::Plugin::Session::State::Cookie   \
	Catalyst::Plugin::Session::Store::DBIC     \
	Catalyst::Plugin::Static::Simple           \
	Catalyst::Runtime                          \
	Catalyst::TraitFor::Request::BrowserDetect \
	Catalyst::View::TT           \
	Catalyst::View::Email        \
	CatalystX::RoleApplicator    \
	Config::General              \
	DBD::mysql                   \
	DBD::Pg                      \
	DBIx::Class::EncodedColumn   \
	DBIx::Class::Schema::Loader  \
	DBIx::Class::TimeStamp       \
	Email::Sender                \
	Email::Valid                 \
	FCGI                         \
	FCGI::ProcManager            \
	File::Pid                    \
	HTML::Restrict               \
	HTML::TagCloud               \
	HTML::TreeBuilder            \
	Method::Signatures::Simple   \
	Module::Install::Catalyst    \
	MooseX::NonMoose             \
	MooseX::MarkAsMethods        \
	Net::Domain::TLD             \
	Text::CSV::Simple            \
	Template::Plugin::Markdown   \
	URI::Encode                  \
	XML::Feed                    \
\
	&& rm -rf /root/.cpan /root/.cpanm


# Copy the webapp files into place and make sure our webapp user owns them

RUN mkdir $APP_DIR

COPY . $APP_DIR

RUN groupadd -r $APP_USER && useradd -r -g $APP_USER $APP_USER

RUN chown -R $APP_USER.$APP_USER $APP_DIR


# Run the webapp!

EXPOSE $APP_PORT

WORKDIR $APP_DIR

USER $APP_USER

CMD script/shinycms_server.pl --port 6174

