# NAME

autobox::Transform - Autobox methods to transform Arrays and Hashes

# CONTEXT

[autobox](https://metacpan.org/pod/autobox) provides the ability to call methods on native types,
e.g. strings, arrays, and hashes as if they were objects.

[autobox::Core](https://metacpan.org/pod/autobox::Core) provides the basic methods for Perl core functions
like `uc`, `map`, and `grep`.

This module, `autobox::Transform`, provides higher level and more
specific methods to transform and manipulate arrays and hashes, in
particular when the values are hashrefs or objects.

# SYNOPSIS

    use autobox::Core;  # map, uniq, sort, join, sum, etc.
    use autobox::Transform;

## Arrays

    # use autobox::Core for ->map etc.

    # filter (grep)
    $book_locations->filter(); # true values
    $books->filter(sub { $_->is_in_library($library) });

    # Flatten arrayrefs-of-arrayrefs
    $authors->map_by("books") # ->books returns an arrayref
    # [ [ $book1, $book2 ], [ $book3 ] ]
    $authors->map_by("books")->flat;
    # [ $book1, $book2, $book3 ]

    # Return reference, even in list context, e.g. in a parameter list
    $book_locations->filter()->to_ref;

    # Return array, even in scalar context
    @books->to_array;

## Arrays with hashrefs/objects

    # $books and $authors below are arrayrefs with either objects or
    # hashrefs (the call syntax is the same)

    $books->map_by("genre");
    $books->map_by([ price_with_tax => $tax_pct ]);

    $books->filter_by("is_sold_out");
    $books->filter_by([ is_in_library => $library ]);
    $books->filter_by([ price_with_tax => $rate ], sub { $_ > 56.00 });
    $books->filter_by("price", sub { $_ > 56.00 });

    # grep_by is an alias for filter_by
    $books->grep_by("is_sold_out");

    $books->uniq_by("id");

    $books->group_by("title"),
    # {
    #     "Leviathan Wakes"       => $books->[0],
    #     "Caliban's War"         => $books->[1],
    #     "The Tree-Body Problem" => $books->[2],
    #     "The Name of the Wind"  => $books->[3],
    # },

    $authors->group_by([ publisher_affiliation => "with" ]),
    # {
    #     'James A. Corey with Orbit'     => $authors->[0],
    #     'Cixin Liu with Head of Zeus'   => $authors->[1],
    #     'Patrick Rothfuss with Gollanz' => $authors->[2],
    # },

    $books->group_by_count("genre"),
    # {
    #     "Sci-fi"  => 3,
    #     "Fantasy" => 1,
    # },

    my $genre_books = $books->group_by_array("genre");
    # {
    #     "Sci-fi"  => [ $sf_book_1, $sf_book_2, $sf_book_3 ],
    #     "Fantasy" => [ $fantasy_book_1 ],
    # },

## Hashes

    # Upper-case the genre name, and make the count say "n books"
    $genre_count->map_each(sub { uc( $_[0] ) => "$_ books" });
    # {
    #     "FANTASY" => "1 books",
    #     "SCI-FI"  => "3 books",
    # },

    # Make the count say "n books"
    $genre_count->map_each_value(sub { "$_ books" });
    # {
    #     "Fantasy" => "1 books",
    #     "Sci-fi"  => "3 books",
    # },

    # Transform each pair to the string "n: genre"
    $genre_count->map_each_to_array(sub { "$_: $_[0]" });
    # [ "1: Fantasy", "3: Sci-fi" ]

    # Return reference, even in list context, e.g. in a parameter list
    %genre_count->to_ref );

    # Return hash, even in scalar context
    $author->book_count->to_hash;

## Combined examples

    my $order_authors = $order->books
        ->uniq_by("isbn")
        ->map_by("author")
        ->map_by("name")->uniq->sort->join(", ");

    my $total_order_amount = $order->books
        ->filter_by([ not_covered_by_vouchers => $vouchers ])
        ->map_by([ price_with_tax => $tax_pct ])
        ->sum;

# DESCRIPTION

High level autobox methods you can call on arrays, arrayrefs, hashes
and hashrefs.

- $array->filter()
- $array->flat()
- $array->as\_ref()
- $array->as\_array()
- $array->map\_by()
- $array->filter\_by()
- $array->uniq\_by()
- $array->group\_by()
- $array->group\_by\_count()
- $array->group\_by\_array()

- $hash->map\_each
- $hash->map\_each\_value
- $hash->map\_each\_to\_array
- $array->as\_ref()
- $array->as\_hash()

## Transforming lists of objects vs list of hashrefs

`map_by`, `filter_by` etc. (all methods named `*_by`) work with
sets of hashrefs or objects.

These methods are called the same way regardless of whether the array
contains objects or hashrefs. The items in the list must all be either
objects or hashrefs.

If the array contains objects, a method is called on each object
(possibly with the arguments provided).

If the array contains hashrefs, the hash key is looked up on each
item.

### Calling accessor methods with arguments

Consider `filter_by`:

    $array->filter_by($accessor, $subref)

If the $accessor is a string, it's a simple lookup/method call.

    # method call without args
    $books->filter_by("price", sub { $_ < 15.0 })
    # becomes $_->price() or $_->{price}

If the $accessor is an arrayref, the first item is the method name,
and the rest of the items are the arguments to the method.

    # method call with args
    $books->filter_by([ price_with_discount => 5.0 ], sub { $_ < 15.0 })
    # becomes $_->price_with_discount(5.0)

### Deprecated syntax

There is an older syntax for calling methods with arguments. It was
abandoned to open up more powerful ways to use grep/filter type
methods. Here it is for reference, in case you run into existing code.

    $array->filter_by($accessor, $args, $subref)
    $books->filter_by("price_with_discount", [ 5.0 ], sub { $_ < 15.0 })

Call the method $accessor on each object using the arguments in the
$args arrayref like so:

    $object->$accessor(@$args)

This style is deprecated, and planned for removal in version 2.000, so if
you have code with the old call style, please:

- Replace your existing code with the new style as soon as possible. The
change is trivial and the code easily found by grep/ack.
- If need be, pin your version to < 2.000 in your cpanfile, dist.ini or
whatever you use to avoid upgrading to an incompatible version.

## List and Scalar Context

Almost all of the methods are context sensitive, i.e. they return a
list in list context and an arrayref in scalar context, just like
autobox::Core.

Beware: you might be in list context when you need an arrayref.

When in doubt, assume they work like `map` and `grep`, and convert
the return value to references where you might have an unobvious list
context. E.g.

    $self->my_method(
        # Wrong, this is list context and wouldn't return an arrayref
        books => $books->filter_by("is_published"),
    );

    $self->my_method(
        # Correct, convert the returned list to an arrayref
        books => [ $books->filter_by("is_published") ],
    );
    $self->my_method(
        # Correct, ensure scalar context to get an array ref
        books => scalar $books->filter_by("is_published"),
    );

    # Probably the nicest, since it goes at the end
    $self->my_method(
        # Correct, use ->to_ref to ensure an array reference is returned
        books => $books->filter_by("is_published")->to_ref,
    );

# METHODS ON ARRAY

## @array->filter($filter\_subref = \*is\_true\*) : @array | @$array

Similar to Perl's `grep`, return an @array with values for which
$filter\_subref returns a true value.

The $filter\_subref is called for each value to check whether this item
should remain in the list (default is to check for true values).

The $filter\_subref should return a true value to remain. $\_ is set to
the current $value.

Examples:

    my @authors = $authors->filter(
        sub { $_->name->publisher =~ /Orbit/ },
    );

### filter and grep

[autobox::Core](https://metacpan.org/pod/autobox::Core)'s `grep` method takes a subref, just like this
method.

## @array->flat() : @array | @$array

Return a (one level) flattened array, assuming the array items
themselves are array refs. I.e.

    [
        [ 1, 2, 3 ],
        [ "a", "b" ],
        [ [ 1, 2 ], { 3 => 4 } ]
    ]->flat

returns

    [ 1, 2, 3, "a", "b ", [ 1, 2 ], { 3 => 4 } ]

This is useful if e.g. a `->map_by("some_method")` returns
arrayrefs of objects which you want to do further method calls
on. Example:

    # ->books returns an arrayref of Book objects with a ->title
    $authors->map_by("books")->flat->map_by("title")

Note: This is different from autobox::Core's ->flatten, which reurns a
list rather than an array and therefore can't be used in this
way.

## @array->to\_ref() : $arrayref

Return the reference to the @array, regardless of context.

Useful for ensuring the last array method return a reference while in
scalar context. Typically:

    do_stuff(
        books => $author->map_by("books")->to_ref,
    );

map\_by is called in list context, so without ->to\_ref it would have
return an array, not an arrayref.

## @array->to\_array() : @array

Return the @array, regardless of context. This is mostly useful if
called on a ArrayRef at the end of a chain of method calls.

# METHODS ON ARRAY-OF-OBJECTS/HASHES

## @array->map\_by($accessor) : @array | @$array

$accessor is either a string, or an arrayref where the first item is a
string.

Call the $accessor on each object in @array, or get the hash key value
on each hashref in @array. Like:

    map { $_->$accessor() }
    # or
    map { $_->{$accessor} }

Examples:

    my @ahthor_names = $authors->map_by("name");
    my $author_names = @publishers->map_by("authors")->map_by("name");

Or get the hash key value. Example:

    my @review_scores = $reviews->map_by("score");

Alternatively the $accessor is an arrayref. The first item is the
accessor name, and the rest of the items are passed as args the method
call. This only works when working with objects, not with hashrefs.

Examples:

    my @prices_including_tax = $books->map_by([ "price_with_tax", $tax_pct ]);
    my $prices_including_tax = $books->map_by([ price_with_tax => $tax_pct ]);

## @array->filter\_by($accessor, $filter\_subref = \*is\_true\*) : @array | @$array

$accessor is either a string, or an arrayref where the first item is a
string.

Call the $accessor on each object in the list, or get the hash key
value on each hashref in the list. The default $filter\_subref includes
true values in the result @array.

Examples:

    my @prolific_authors = $authors->filter_by("is_prolific");

Alternatively the $accessor is an arrayref. The first item is the
accessor name, and the rest of the items are passed as args the method
call. This only works when working with objects, not with hashrefs.

Examples:

    my @books_to_charge_for = $books->filter_by([ price_with_tax => $tax_pct ]);

### The $filter\_subref

The $filter\_subref is called with the value returned from the $accessor
to check whether this item should remain in the list (default is to
check for true values).

The $filter\_subref should return a true value to remain. $\_ is set to
the current $value.

Examples:

    my @authors = $authors->filter_by(
        "publisher",
        sub { $_->name =~ /Orbit/ },
    );

    my @authors = $authors->filter_by(
        [ publisher_affiliation => "with" ],
        sub { /Orbit/ },
    );

Note: if you do something complicated with the $filter\_subref, it might
be easier and more readable to simply use `$array-$<gt`grep()> from
[autobox::Core](https://metacpan.org/pod/autobox::Core).

### Alias

`grep_by` is an alias for `filter_by`. Unlike `grep` vs `filter`
it works exaclty the same way.

## @array->uniq\_by($accessor) : @array | @$array

$accessor is either a string, or an arrayref where the first item is a
string.

Call the $accessor on each object in the list, or get the hash key
value on each hashref in the list. Return list of items wich have a
unique set of return values. The order is preserved. On duplicates,
keep the first occurrence.

Examples:

    # You have gathered multiple Author objects with duplicate ids
    my @authors = $authors->uniq_by("author_id");

Alternatively the $accessor is an arrayref. The first item is the
accessor name, and the rest of the items are passed as args the method
call. This only works when working with objects, not with hashrefs.

Examples:

    my @example_book_at_price_point = $books->uniq_by(
        [ price_with_tax => $tax_pct ],
    );

## @array->group\_by($accessor, $value\_subref = object) : %key\_value | %$key\_value

$accessor is either a string, or an arrayref where the first item is a
string.

Call `->$accessor` on each object in the array, or get the hash
key for each hashref in the array (just like `->map_by`) and
group the values as keys in a hashref.

The default $value\_subref puts each object in the list as the hash
value. If the key is repeated, the value is overwritten with the last
object.

Example:

    my $title_book = $books->group_by("title");
    # {
    #     "Leviathan Wakes"       => $books->[0],
    #     "Caliban's War"         => $books->[1],
    #     "The Tree-Body Problem" => $books->[2],
    #     "The Name of the Wind"  => $books->[3],
    # },

### The $value\_subref

This is a bit tricky to use, so the most common thing would probably
be to use one of the more specific group\_by-methods (see below). It
should be capable enough to achieve what you need though, so here's
how it works:

The hash key is whatever is returned from `$object->$accessor`.

The hash value is whatever is returned from

    my $new_value = $value_sub->($current_value, $object, $key);

where:

- `$current` value is the current hash value for this key (or undef if the first one).
- `$object` is the current item in the list. The current $\_ is also set to this.
- `$key` is the key returned by $object->$accessor(@$args)

## @array->group\_by\_count($accessor) : %key\_count | %$key\_count

$accessor is either a string, or an arrayref where the first item is a
string.

Just like `group_by`, but the hash values are the the number of
instances each $accessor value occurs in the list.

Example:

    $books->group_by_count("genre"),
    # {
    #     "Sci-fi"  => 3,
    #     "Fantasy" => 1,
    # },

`$book->genre()` returns the genre string. There are three books
counted for the "Sci-fi" key.

## @array->group\_by\_array($accessor) : %key\_objects | %$key\_objects

$accessor is either a string, or an arrayref where the first item is a
string.

Just like `group_by`, but the hash values are arrayrefs containing
the objects which has each $accessor value.

Example:

    my $genre_books = $books->group_by_array("genre");
    # {
    #     "Sci-fi"  => [ $sf_book_1, $sf_book_2, $sf_book_3 ],
    #     "Fantasy" => [ $fantasy_book_1 ],
    # },

$book->genre() returns the genre string. The three Sci-fi book objects
are collected under the Sci-fi key.

# METHODS ON HASH

## %hash->map\_each($key\_value\_subref) : %new\_hash | %$new\_hash

Map each key-value pair in the hash using the
$key\_value\_subref. Similar to how to how map transforms a list into
another list, map\_each transforms a hash into another hash.

`$key_value_subref->($key, $value)` is called for each pair (with
$\_ set to the value).

The subref should return an even-numbered list with zero or more
key-value pairs which will make up the %new\_hash. Typically two items
are returned in the list (the key and the value).

### Example

    { a => 1, b => 2 }->map_each(sub { "$_[0]$_[0]" => $_ * 2 });
    # Returns { aa => 2, bb => 4 }

## %hash->map\_each\_value($value\_subref) : %new\_hash | %$new\_hash

Map each value in the hash using the $value\_subref, but keep the keys
the same.

`$value_subref->($key, $value)` is called for each pair (with $\_
set to the value).

The subref should return a single value for each key which will make
up the %new\_hash (with the same keys but with new mapped values).

### Example

    { a => 1, b => 2 }->map_each_value(sub { $_ * 2 });
    # Returns { a => 2, b => 4 }

## %hash->map\_each\_to\_array($item\_subref) : @new\_array | @$new\_array

Map each key-value pair in the hash into a list using the
$item\_subref.

`$item_subref->($key, $value)` is called for each pair (with $\_
set to the value) in key order.

The subref should return zero or more list items which will make up
the @new\_array. Typically one item is returned.

### Example

    { a => 1, b => 2 }->map_each_to_array(sub { "$_[0]-$_" });
    # Returns [ "a-1", "b-2" ]

## %hash->to\_ref() : $hashref

Return the reference to the %hash, regardless of context.

Useful for ensuring the last hash method return a reference while in
scalar context. Typically:

    do_stuff(
        genre_count => $books->group_by_count("genre")->to_ref,
    );

## %hash->to\_hash() : %hash

Return the %hash, regardless of context. This is mostly useful if
called on a HashRef at the end of a chain of method calls.

# AUTOBOX AND VANILLA PERL

## Raison d'etre

[autobox::Core](https://metacpan.org/pod/autobox::Core) is awesome, for a variety of reasons.

- It cuts down on dereferencing punctuation clutter, both by using
methods on references and by using ->elements to deref arrayrefs.
- It makes map and grep transforms read in the same direction it's
executed.
- It makes it easier to write those things in a natural order. No need
to move the cursor around a lot just to fix dereferencing, order of
operations etc.

On top of this, [autobox::Transform](https://metacpan.org/pod/autobox::Transform) provides a few higher level
methods for mapping, filtering and sorting common cases which are easier
to read and write.

Since they are at a slightly higher semantic level, once you know them
they also provide a more specific meaning than just "map" or "grep".

(Compare the difference between seeing a "map" and seeing a "foreach"
loop. Just seeing the word "map" hints at what type of thing is going
on here: transforming a list into another list).

The methods of autobox::Transform are not suitable for all
cases, but when used appropriately they will lead to much more clear,
succinct and direct code, especially in conjunction with
autobox::Core.

## Code Comparison

These examples are only for when there's a straightforward and simple
Perl equivalent.

    ### map_by - method call: $books are Book objects
    my @genres = map { $_->genre() } @$books;
    my @genres = $books->map_by("genre");

    my $genres = [ map { $_->genre() } @$books ];
    my $genres = $books->map_by("genre");

    # With sum from autobox::Core / List::AllUtils
    my $book_order_total = sum(
        map { $_->price_with_tax($tax_pct) } @{$order->books}
    );
    my $book_order_total = $order->books
        ->map_by([ price_with_tax => $tax_pct ])->sum;

    ### map_by - hash key: $books are book hashrefs
    my @genres = map { $_->{genre} } @$books;
    my @genres = $books->map_by("genre");



    ### filter_by - method call: $books are Book objects
    my $sold_out_books = [ grep { $_->is_sold_out } @$books ];
    my $sold_out_books = $books->filter_by("is_sold_out");
    my $sold_out_books = $books->grep_by("is_sold_out");

    my $books_in_library = [ grep { $_->is_in_library($library) } @$books ];
    my $books_in_library = $books->filter_by([ is_in_library => $library ]);

    ### filter_by - hash key: $books are book hashrefs
    my $sold_out_books = [ grep { $_->{is_sold_out} } @$books ];
    my $sold_out_books = $books->filter_by("is_sold_out");



    ### uniq_by - method call: $books are Book objects
    my %seen; my $distinct_books = [ grep { ! %seen{ $_->id // "" }++ } @$books ];
    my $distinct_books = $books->uniq_by("id");

    ### uniq_by - hash key: $books are book hashrefs
    my %seen; my $distinct_books = [ grep { ! %seen{ $_->{id} // "" }++ } @$books ];
    my $distinct_books = $books->uniq_by("id");


    #### flat - $author->books returns an arrayref of Books
    my $author_books = [ map { @{$_->books} } @$authors ]
    my $author_books = $authors->map_by("books")->flat

# DEVELOPMENT

## Author

Johan Lindstrom, `<johanl [AT] cpan.org>`

## Source code

[https://github.com/jplindstrom/p5-autobox-Transform](https://github.com/jplindstrom/p5-autobox-Transform)

## Bug reports

Please report any bugs or feature requests on GitHub:

[https://github.com/jplindstrom/p5-autobox-Transform/issues](https://github.com/jplindstrom/p5-autobox-Transform/issues).

# COPYRIGHT & LICENSE

Copyright 2016- Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
