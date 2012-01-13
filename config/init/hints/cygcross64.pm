# Copyright (C) 2005-2011, Parrot Foundation.

package init::hints::cygcross64;

use strict;
use warnings;

sub _real_path {
    my ($path) = @_;
    $path = `cygpath --mixed '$path'`;
    chomp $path;
    return $path;
}

sub runstep {
    my (undef, $conf) = @_;

    # Use 64-bit integers
    $conf->options->set(intval => 'long long');

    # Translate absolute paths from UNIX-style to Windows-style
    my @keys = qw{prefix exec_prefix bindir build_dir tempdir libdir includedir};
    my %dirs;
    @dirs{@keys} = map { _real_path $conf->data->get($_) } @keys;
    $conf->data->set(%dirs);

    # Identify as win32
    $conf->data->set(
        win32       => 1,
        platform    => 'win32',
        osname      => 'MSWin32'
    );

    # Mark as cross-compilation
    $conf->data->set(cygcross => 1);

    # Hardcode architecture
    $conf->skip_step('auto::arch');
    $conf->data->set(
        archname    => 'x86_64-w64-mingw32',
        cpuarch     => 'amd64'
    );

    # Assume Windows 2000 or above
    $conf->data->set(ccflags => '-DWIN32 -DWINVER=0x0500 ');

    # Create Parrot as shared library
    $conf->data->set(
        parrot_is_shared    => 1,
        has_dynamic_linking => 1,
        has_static_linking  => 0,
        ld_share_flags      => '-shared',
        ld_load_flags       => '-shared',
        sym_export          => '__declspec(dllexport)',
        sym_import          => '__declspec(dllimport)'
    );

    # Setup default cross toolchain
    $conf->data->set(cc => 'x86_64-w64-mingw32-gcc')
        unless $conf->options->get('cc');
    $conf->data->set(ld => 'x86_64-w64-mingw32-gcc')
        unless $conf->options->get('ld');
    $conf->data->set(link => 'x86_64-w64-mingw32-gcc')
        unless $conf->options->get('link');

    # Remove incorrect default library path
    my $ldflags = $conf->data->get('ldflags');
    my $linkflags = $conf->data->get('linkflags');
    $ldflags =~ s{-L/usr/local/lib\s*}{};
    $linkflags =~ s{-L/usr/local/lib\s*}{};
    $conf->data->set(
        ldflags     => $ldflags,
        linkflags   => $linkflags
    );

    # Link non-default Windows libs
    $conf->data->set(libs => '-lws2_32');

    # Setup built Parrot
    $conf->data->set(
        libparrot_ldflags   => '-L. -lparrot',
        libparrot_linkflags => '-L. -lparrot',
    );

    # Setup installed Parrot
    my $bindir = $conf->data->get('bindir');
    $bindir =~ s{ }{\\ }g;
    $conf->data->set(
        inst_libparrot_ldflags   => "-L$bindir -lparrot",
        inst_libparrot_linkflags => "-L$bindir -lparrot"
    );

    # NCI testing
    $conf->data->set(ncilib_link_extra => 'src/libnci_test.def');
}

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
