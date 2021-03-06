use strict;
use warnings;
use utf8;

use Test::More;

use HTTP::Headers;
use Sort::Key qw(keysort);
use POSIX 'strcoll';

use FixMyStreet;
use mySociety::Locale;

# check that the mo files have been generated
die "You need to run 'commonlib/bin/gettext-makemo --quiet FixMyStreet' "
  . "to generate the *.mo files needed."
  unless -e FixMyStreet->path_to(
    'locale/nb_NO.UTF-8/LC_MESSAGES/FixMyStreet.mo');

# Test the language negotiation works
my $lang = mySociety::Locale::negotiate_language(
    'en-gb,English,en_GB|es,Spanish,es_ES',
    undef,
    HTTP::Headers->new(
        Accept_Language => 'es,en-gb;q=0.6,en;q=0.4'
    )
);
is $lang, 'es', 'Language negotiation works okay';

# Example strings
my $english = "Please enter a valid email";
my $norwegian = "Legg til en gyldig e-post";

# set english as the language
mySociety::Locale::negotiate_language(    #
    'en-gb,English,en_GB|nb,Norwegian,nb_NO', 'en_GB'
);

mySociety::Locale::gettext_domain( 'FixMyStreet', 1 );
mySociety::Locale::change();
is _($english), $english, "english to english";

mySociety::Locale::change('nb');
is _($english), $norwegian, "english to norwegian";

# check that being in a deep directory does not confuse the code
chdir FixMyStreet->path_to('t/app/controller') . '';
mySociety::Locale::gettext_domain( 'FixMyStreet', 1,
    FixMyStreet->path_to('locale')->stringify );
mySociety::Locale::change('nb');
is _($english), $norwegian, "english to norwegian (deep directory)";

# test that sorting works as expected in the right circumstances...
my @random_sorted  = qw( Å Z Ø A );
my @EN_sorted      = qw( A Å Ø Z );
my @NO_sorted      = qw( A Z Ø Å );
my @default_sorted = qw( A Z Å Ø );

SKIP: {

    mySociety::Locale::negotiate_language(    #
        'en-gb,English,en_GB', 'en_GB'
    );
    mySociety::Locale::change();

    no locale;

    is_deeply( [ sort @random_sorted ],
        \@default_sorted, "sort correctly with no locale" );

    is_deeply( [ keysort { $_ } @random_sorted ],
        \@default_sorted, "keysort correctly with no locale" );

    skip 'Will not pass on Mac', 1 if $^O eq 'darwin';

    # Note - this obeys the locale
    is_deeply( [ sort { strcoll( $a, $b ) } @random_sorted ],
        \@EN_sorted, "sort strcoll correctly with no locale (to 'en_GB')" );
}

SKIP: {
    skip 'Will not pass on Mac', 2 if $^O eq 'darwin';

    mySociety::Locale::negotiate_language(    #
        'en-gb,English,en_GB', 'en_GB'
    );
    mySociety::Locale::change();
    use locale;

    is_deeply( [ sort @random_sorted ],
        \@EN_sorted, "sort correctly with use locale 'en_GB'" );

    # is_deeply( [ keysort { $_ } @random_sorted ],
    #     \@EN_sorted, "keysort correctly with use locale 'en_GB'" );

    is_deeply( [ sort { strcoll( $a, $b ) } @random_sorted ],
        \@EN_sorted, "sort strcoll correctly with use locale 'en_GB'" );
}

SKIP: {
    skip 'Will not pass on Mac', 2 if $^O eq 'darwin';

    mySociety::Locale::negotiate_language(    #
        'nb-no,Norwegian,nb_NO', 'nb_NO'
    );
    mySociety::Locale::change();
    use locale;

    is_deeply( [ sort @random_sorted ],
        \@NO_sorted, "sort correctly with use locale 'nb_NO'" );

    # is_deeply( [ keysort { $_ } @random_sorted ],
    #     \@NO_sorted, "keysort correctly with use locale 'nb_NO'" );

    is_deeply( [ sort { strcoll( $a, $b ) } @random_sorted ],
        \@NO_sorted, "sort strcoll correctly with use locale 'nb_NO'" );
}

subtest "check that code is only called once by in_gb_locale" => sub {

    my $scalar_counter = 0;
    my $out = mySociety::Locale::in_gb_locale { $scalar_counter++ };
    is $scalar_counter, 1, "code called once in scalar context";

    my $list_counter = 0;
    my @out = mySociety::Locale::in_gb_locale { $list_counter++ };
    is $list_counter, 1, "code called once in list context";

};

done_testing();
