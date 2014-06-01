#!/usr/bin/perl

# Combine authz files given in arguments into a single authz file
# and print it on stdout. If files have matching rules, last file wins,
# so make sure authz_general comes first.


use warnings;
use strict;

use Ini;
use File::Basename;


# This configures how included file name matches against svn paths inside it
# #filename# will be replaced by the name of the file from authz_files
my $pat = '^/#filename#(/.*)?$';


###############################################################################


my (%groups_all, %settings_all, %acl_common, %groups_common);


open AC, 'groups_common' or die "Could not open groups_common";

for (<AC>) {
        chomp;
        next if /^(#.*)?$/;
        die "Error parsing groups_common" unless ~/^\w+;(r(w)?)?;[\w, ]+$/;

        my ($group, $level, $members) = split /;/;
        $acl_common{$group} = $level;
        $groups_common{$group} = $members;
}


for (@ARGV) {
	my $file = $_;
	my $fname = basename $file;
	(my $patsubst = $pat) =~ s/#filename#/$fname/;
	my $name_regex = qr($patsubst);


	my $syntax_ok = 1;

	my $ini = new Config::Abstract::Ini($file);
	my %settings = $ini->get_all_settings;

	my %groups = $ini->get_entry('groups');
	for (keys %groups) {
		if (!/\w+/) {
			$syntax_ok = 0;
			print "Error in group name: $_\n";
		}
	}
	delete $settings{'groups'};


	for my $path (keys %settings) {
		unless ($file eq 'authz_general' || $path =~ $name_regex) {
			$syntax_ok = 0;
			print STDERR "$fname: Invalid path specification: $path\n";
		}

		for my $acl (keys %{$settings{$path}}) {
			unless (${settings{$path}}{$acl} =~ /^(rw?)?$/) {
				$syntax_ok = 0;
				print STDERR "$fname: Mode ".${settings{$path}}{$acl}." is invalid for $acl\n"; 
			}

			if ($acl =~ /^@/) {
				if (!$groups{substr $acl, 1}) {
					$syntax_ok = 0;
					print STDERR "$fname: Group ".(substr $acl, 1)." not defined or value is incorrect\n";
				}
				${settings{$path}}{"@".${fname}."_".(substr $acl, 1)} = delete ${settings{$path}}{$acl};
			}

            for (keys %acl_common) {
                    ${settings{$path}}{'@'.$_} = $acl_common{$_};
            }
		}
	};

	if (!$syntax_ok) {
		print STDERR "Skipping file $fname because of syntax errors\n";
		next;
	} 

	for (keys %groups) {
		$groups_all{${fname}."_".$_} = $groups{$_};
	}
	for (keys %settings) {
		$settings_all{$_} = $settings{$_};
	}
}


if (%groups_all && %settings_all) {
	print "[groups]\n";
        for (sort keys %groups_common) {
                print "$_ = $groups_common{$_}\n";
        }

	for (sort keys %groups_all) {
		print "$_ = $groups_all{$_}\n";
	}

	for my $path (sort keys %settings_all) {
		print "\n[$path]\n";
		for my $acl (reverse sort keys %{$settings_all{$path}}) {
			print "$acl = ".${settings_all{$path}}{$acl}."\n";
		}
	}
}

exit 0;
