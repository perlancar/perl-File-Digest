package File::Digest;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(digest_files);

use Perinci::Object;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Calculate file checksum/digest (using various algorithms)',
};

my %arg_file = (
    file => {
        schema => ['filename*'],
        req => 1,
        pos => 0,
        cmdline_aliases => {f=>{}},
    },
);

my %arg_files = (
    files => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*', of=>'filename*'],
        req => 1,
        pos => 0,
        greedy => 1,
        cmdline_aliases => {f=>{}},
    },
);

my %arg_algorithm = (
    algorithm => {
        schema => ['str*', in=>[qw/crc32 md5 sha1 sha224 sha256 sha384 sha512 sha512224 sha512256/]],
        default => 'md5',
        cmdline_aliases => {a=>{}},
    },
);

$SPEC{digest_file} = {
    v => 1.1,
    summary => 'Calculate file checksum/digest (using various algorithms)',
    description => <<'_',

Return 400 status when algorithm is unknown/unsupported.

_
    args => {
        %arg_file,
        %arg_algorithm,
    },
};
sub digest_file {
    my %args = @_;

    my $file = $args{file};
    my $algo = $args{algorithm} // 'md5';

    unless (-f $file) {
        log_warn("Can't open %s: no such file", $file);
        return [404, "No such file '$file'"];
    }
    open my($fh), "<", $file or do {
        log_warn("Can't open %s: %s", $file, $!);
        return [500, "Can't open '$file': $!"];
        next;
    };
    if ($algo eq 'md5') {
        require Digest::MD5;
        my $ctx = Digest::MD5->new;
        $ctx->addfile($fh);
        return [200, "OK", $ctx->hexdigest];
    } elsif ($algo =~ /\Asha(512224|512256|224|256|384|512|1)\z/) {
        require Digest::SHA;
        my $ctx = Digest::SHA->new($1);
        $ctx->addfile($fh);
        return [200, "OK", $ctx->hexdigest];
    } elsif ($algo eq 'crc32') {
        require Digest::CRC;
        my $ctx = Digest::CRC->new(type=>'crc32');
        $ctx->addfile($fh);
        return [200, "OK", $ctx->hexdigest];
    } else {
        return [400, "Invalid/unsupported algorithm '$algo'"];
    }
}

$SPEC{digest_files} = {
    v => 1.1,
    summary => 'Calculate file checksum/digest (using various algorithms)',
    description => <<'_',

Dies when algorithm is unsupported/unknown.

_
    args => {
        %arg_files,
        %arg_algorithm,
    },
};
sub digest_files {
    my %args = @_;

    my $files = $args{files};
    my $algo  = $args{algorithm} // 'md5';

    my $envres = envresmulti();
    my @res;

    for my $file (@$files) {
        my $itemres = digest_file(file => $file, algorithm=>$algo);
        die $itemres->[1] if $itemres->[0] == 400;
        $envres->add_result($itemres->[0], $itemres->[1], {item_id=>$file});
        push @res, {file=>$file, digest=>$itemres->[2]} if $itemres->[0] == 200;
    }

    $envres = $envres->as_struct;
    $envres->[2] = \@res;
    $envres->[3]{'table.fields'} = [qw/file digest/];
    $envres;
}

1;
# ABSTRACT:

=head1 SYNOPSIS

 use File::Digest qw(digest_files);

 my $res = digest_files(
     files => ["file1", "file2"],
     algorithm => 'md5', # default md5, available also: crc32, sha1, sha256
 );


=head1 DESCRIPTION


=head1 SEE ALSO

L<sum> from L<PerlPowerTools> (which only supports older algorithms like CRC32).

Backend modules: L<Digest::CRC>, L<Digest::MD5>, L<Digest::SHA>.

L<xsum> from L<App::xsum> which can also check checksums/digests from checksum
file e.g. F<MD5SUMS>.

=cut
