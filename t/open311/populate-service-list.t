#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FixMyStreet::App;

use FindBin;
use lib "$FindBin::Bin/../perllib";
use lib "$FindBin::Bin/../commonlib/perllib";

use_ok( 'Open311::PopulateServiceList' );
use_ok( 'Open311' );


my $processor = Open311::PopulateServiceList->new( council_list => [] );
ok $processor, 'created object';

subtest 'check basic functionality' => sub {
    FixMyStreet::App->model('DB::Contact')->search( { area_id => 1 } )->delete();

    my $xml = qq{<?xml version="1.0" encoding="utf-8"?>
<services>
	<service>
		<service_code>001</service_code>
		<service_name>Cans left out 24x7</service_name>
		<description>Garbage or recycling cans that have been left out for more than 24 hours after collection. Violators will be cited.</description>
		<metadata>false</metadata>
		<type>realtime</type>
		<keywords>lorem, ipsum, dolor</keywords>
		<group>sanitation</group>
	</service>
	<service>
		<service_code>002</service_code>
		<metadata>false</metadata>
		<type>realtime</type>
		<keywords>lorem, ipsum, dolor</keywords>
		<group>street</group>
		<service_name>Construction plate shifted</service_name>
		<description>Metal construction plate covering the street or sidewalk has been moved.</description>
	</service>
	<service>
		<service_code>003</service_code>
		<metadata>false</metadata>
		<type>realtime</type>
		<keywords>lorem, ipsum, dolor</keywords>
		<group>street</group>
		<service_name>Curb or curb ramp defect</service_name>
		<description>Sidewalk curb or ramp has problems such as cracking, missing pieces, holes, and/or chipped curb.</description>
	</service>
</services>
};

    my $simple = XML::Simple->new();
    my $obj;

    eval {
        $obj = $simple->XMLin( $xml );
    };

    my $council = FixMyStreet::App->model('DB::Open311Conf')->new( {
        area_id => 1
    } );

    my $processor = Open311::PopulateServiceList->new( council_list => [] );
    $processor->_current_council( $council );
    $processor->process_services( $obj );

    my $contact_count = FixMyStreet::App->model('DB::Contact')->search( { area_id => 1 } )->count();
    is $contact_count, 3, 'correct number of contacts';
};

subtest 'check duplicate service name issues error' => sub {
    FixMyStreet::App->model('DB::Contact')->search( { area_id => 1 } )->delete();

    my $contact = FixMyStreet::App->model('DB::Contact')->create(
        {
            area_id => 1,
            email =>   '009',
            category => 'Cans left out 24x7',
            confirmed => 1,
            deleted => 0,
            editor => $0,
            whenedited => \'ms_current_timestamp()',
            note => 'test contact',
        }
    );

    ok $contact, 'contact created';

    my $xml = qq{<?xml version="1.0" encoding="utf-8"?>
<services>
	<service>
		<service_code>001</service_code>
		<service_name>Cans left out 24x7</service_name>
		<description>Garbage or recycling cans that have been left out for more than 24 hours after collection. Violators will be cited.</description>
		<metadata>false</metadata>
		<type>realtime</type>
		<keywords>lorem, ipsum, dolor</keywords>
		<group>sanitation</group>
	</service>
	<service>
		<service_code>002</service_code>
		<metadata>false</metadata>
		<type>realtime</type>
		<keywords>lorem, ipsum, dolor</keywords>
		<group>street</group>
		<service_name>Construction plate shifted</service_name>
		<description>Metal construction plate covering the street or sidewalk has been moved.</description>
	</service>
	<service>
		<service_code>003</service_code>
		<metadata>false</metadata>
		<type>realtime</type>
		<keywords>lorem, ipsum, dolor</keywords>
		<group>street</group>
		<service_name>Curb or curb ramp defect</service_name>
		<description>Sidewalk curb or ramp has problems such as cracking, missing pieces, holes, and/or chipped curb.</description>
	</service>
</services>
};

    my $simple = XML::Simple->new();
    my $obj;

    eval {
        $obj = $simple->XMLin( $xml );
    };

    my $council = FixMyStreet::App->model('DB::Open311Conf')->new( {
        area_id => 1
    } );

    my $processor = Open311::PopulateServiceList->new( council_list => [] );
    $processor->_current_council( $council );
    $processor->process_services( $obj );

    $contact->discard_changes;
    is $contact->email, '009', 'email unchanged';
    is $contact->confirmed, 1, 'contact still confirmed';
    is $contact->deleted, 0, 'contact still not deleted';

    my $contact_count = FixMyStreet::App->model('DB::Contact')->search( { area_id => 1 } )->count();
    is $contact_count, 3, 'correct number of contacts';
};

subtest 'check category name changed if updated' => sub {
    FixMyStreet::App->model('DB::Contact')->search( { area_id => 1 } )->delete();

    my $contact = FixMyStreet::App->model('DB::Contact')->create(
        {
            area_id => 1,
            email =>   '001',
            category => 'Bins left out 24x7',
            confirmed => 1,
            deleted => 0,
            editor => $0,
            whenedited => \'ms_current_timestamp()',
            note => 'test contact',
        }
    );

    ok $contact, 'contact created';

    my $xml = qq{<?xml version="1.0" encoding="utf-8"?>
<services>
	<service>
		<service_code>001</service_code>
		<service_name>Cans left out 24x7</service_name>
		<description>Garbage or recycling cans that have been left out for more than 24 hours after collection. Violators will be cited.</description>
		<metadata>false</metadata>
		<type>realtime</type>
		<keywords>lorem, ipsum, dolor</keywords>
		<group>sanitation</group>
	</service>
	<service>
		<service_code>002</service_code>
		<metadata>false</metadata>
		<type>realtime</type>
		<keywords>lorem, ipsum, dolor</keywords>
		<group>street</group>
		<service_name>Construction plate shifted</service_name>
		<description>Metal construction plate covering the street or sidewalk has been moved.</description>
	</service>
	<service>
		<service_code>003</service_code>
		<metadata>false</metadata>
		<type>realtime</type>
		<keywords>lorem, ipsum, dolor</keywords>
		<group>street</group>
		<service_name>Curb or curb ramp defect</service_name>
		<description>Sidewalk curb or ramp has problems such as cracking, missing pieces, holes, and/or chipped curb.</description>
	</service>
</services>
};

    my $simple = XML::Simple->new();
    my $obj;

    eval {
        $obj = $simple->XMLin( $xml );
    };

    my $council = FixMyStreet::App->model('DB::Open311Conf')->new( {
        area_id => 1
    } );

    my $processor = Open311::PopulateServiceList->new( council_list => [] );
    $processor->_current_council( $council );
    $processor->process_services( $obj );

    $contact->discard_changes;
    is $contact->email, '001', 'email unchanged';
    is $contact->category, 'Cans left out 24x7', 'category changed';
    is $contact->confirmed, 1, 'contact still confirmed';
    is $contact->deleted, 0, 'contact still not deleted';

    my $contact_count = FixMyStreet::App->model('DB::Contact')->search( { area_id => 1 } )->count();
    is $contact_count, 3, 'correct number of contacts';
};

done_testing();
