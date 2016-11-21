package File::Digest;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Exporter qw(import);
our @EXPORT_OK = qw(digest_files check_file_digest);

use Perinci::Object;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Calculate and check file checksum/digest '.
        '(using various algorithms)',
};

$SPEC{digest_files} = {
    v => 1.1,
    summary => 'Calculate file checksums/digests (using various algorithms)',
    args => {
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            req => 1,
            pos => 0,
            greedy => 1,
            cmdline_aliases => {f=>{}},
        },
        algorithm => {
            schema => ['str*', in=>[qw/crc32 md5 sha1 sha256/]],
            default => 'md5',
            cmdline_aliases => {a=>{}},
        },
    },
};
sub digest_files {

    my %args = @_;

    my $files = $args{files};
    my $algo  = $args{algorithm} // 'md5';

    my $envres = envresmulti();
    my @res;

    for my $file (@$files) {
        unless (-f $file) {
            $log->warnf("Can't open %s: no such file", $file);
            $envres->add_result(404, "No such file", {item_id=>$file});
            next;
        }
        open my($fh), "<", $file or do {
            $log->warnf("Can't open %s: %s", $file, $!);
            $envres->add_result(500, "Can't open: $!", {item_id=>$file});
            next;
        };
        if ($algo eq 'md5') {
            require Digest::MD5;
            my $ctx = Digest::MD5->new;
            $ctx->addfile($fh);
            $envres->add_result(200, "OK", {item_id=>$file});
            push @res, {file=>$file, digest=>$ctx->hexdigest};
        } elsif ($algo eq 'sha1') {
            require Digest::SHA;
            my $ctx = Digest::SHA->new(1);
            $ctx->addfile($fh);
            $envres->add_result(200, "OK", {item_id=>$file});
            push @res, {file=>$file, digest=>$ctx->hexdigest};
        } elsif ($algo eq 'sha256') {
            require Digest::SHA;
            my $ctx = Digest::SHA->new(256);
            $ctx->addfile($fh);
            $envres->add_result(200, "OK", {item_id=>$file});
            push @res, {file=>$file, digest=>$ctx->hexdigest};
        } elsif ($algo eq 'crc32') {
            require Digest::CRC;
            my $ctx = Digest::CRC->new(type=>'crc32');
            $ctx->addfile($fh);
            $envres->add_result(200, "OK", {item_id=>$file});
            push @res, {file=>$file, digest=>$ctx->hexdigest};
        } else {
            die "Invalid/unsupported algorithm '$algo'";
        }
    }

    $envres = $envres->as_struct;
    $envres->[2] = \@res;
    $envres->[3]{'table.fields'} = [qw/file digest/];
    $envres;
}

$SPEC{check_file_digest} = {
    v => 1.1,
    summary => 'Calculate file checksums/digests (using various algorithms)',
};
sub check_file_digest {
    [501, "Not yet implemented"];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

 use File::Digest qw(digest_files check_file_digest);

 my $res = digest_files(
     files => ["file1", "file2"],
     algorithm => 'md5', # default md5, available also: crc32, sha1, sha256
 );


=head1 DESCRIPTION


=head1 SEE ALSO

L<sum> from L<PerlPowerTools> (which only supports older algorithms like CRC32).

Backend modules: L<Digest::CRC>, L<Digest::MD5>, L<Digest::SHA>.

=cut
