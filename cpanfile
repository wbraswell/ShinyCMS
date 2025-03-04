# WBRASWELL 20250304: all requirements, test requirements, and recommendations below were copied from the old now-deprecated Makefile.PL
requires 'Catalyst::Runtime', '5.80004';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'parent';
requires 'Config::General';

requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::DBIC';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Authentication::Realm::SimpleDB';
requires 'Catalyst::View::TT';
requires 'Catalyst::View::Email';
requires 'Catalyst::TraitFor::Request::BrowserDetect';
requires 'CatalystX::RoleApplicator';
requires 'DBIx::Class::EncodedColumn';
requires 'DBIx::Class::Schema::Loader';
requires 'DBIx::Class::TimeStamp';
requires 'Method::Signatures::Simple';
requires 'MooseX::NonMoose';
requires 'MooseX::MarkAsMethods';
requires 'Captcha::reCAPTCHA';
requires 'Email::Sender', '0.102360';
requires 'Email::Valid';
requires 'File::Pid';
requires 'HTML::Restrict';
requires 'HTML::TagCloud';
requires 'HTML::TreeBuilder';
requires 'Net::Akismet';
requires 'Net::Domain::TLD';
requires 'Text::CSV::Simple';
requires 'URI::Encode';
requires 'XML::Feed';

on 'test' => sub {
    requires 'Devel::Cover';
    requires 'Devel::Cover::Report::Codecov';
    requires 'LWP::Protocol::https';
    requires 'Test::Exception';
    requires 'Test::MockObject';
    requires 'Test::More';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::WWW::Mechanize::Catalyst::WithContext';
};

recommends 'FCGI';
recommends 'FCGI::ProcManager';
recommends 'Template::Plugin::Markdown';

