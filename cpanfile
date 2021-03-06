requires 'perl', '5.008001';

requires 'autobox';
requires 'autobox::Core';
requires 'Carp';
requires 'parent';
requires 'Sort::Maker';
requires 'List::MoreUtils';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Differences';
    requires 'Test::Exception';
    requires 'Moo';
};
