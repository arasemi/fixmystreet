package FixMyStreet::SendReport::Email::Highways;

use Moo;
extends 'FixMyStreet::SendReport::Email';

sub build_recipient_list {
    my ( $self, $row, $h ) = @_;

    return unless @{$self->bodies} == 1;
    my $body = $self->bodies->[0];

    # We don't care what the category was, look up the Pothole contact
    my $contact = $row->result_source->schema->resultset("Contact")->not_deleted->find({
        body_id => $body->id,
        category => 'Pothole',
    });
    return unless $contact;

    @{$self->to} = map { [ $_, $body->name ] } split /,/, $contact->email;
    return 1;
}

1;
