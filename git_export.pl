#!/usr/bin/perl
################################################################################
#
#                  P E R L   S P E C I F I C A T I O N
#             COPYRIGHT 2014 MOTOROLA, INC. ALL RIGHTS RESERVED.
#                    MOTOROLA CONFIDENTIAL PROPRIETARY
#
################################################################################
#
# FILE NAME: git_export.pl
#
# WARNING!!!!!!!
# Do not modify this script in /local_data/tools/bin!
# This script is under version control at /local_data/repos/tools.git.
# When releasing this script, pull changes to the /local_data/tools git repository
#
#---------------------------------- PURPOSE ------------------------------------
# This script is to be used to import content that was extracted from GIT
# Repositories into ClearCase. 
#  
# 
#--------------------------- PROJECT SPECIFIC DATA -----------------------------
# 
# ClearCase Requirements: In a View
# Your config spec will be reset to a midified version of the released
# config_spec.txt for the baseline provided.
# eg. /vobs/mackinaw_releases/config_spec.txt@@/main/fl08_sr7_15_5_mackinaw_main/23
#
#
#
#
#
#----------------------------- MODULE INCLUDES ---------------------------------

use strict;
use File::Basename;
use Getopt::Long;
use Term::ANSIColor qw(:constants);
use Cwd;
use warnings;
use List::Uniq ':all';

# Signal Handling
$SIG{INT}  = 'interrupt';
$SIG{TERM} = 'interrupt';
$SIG{HUP}  = 'interrupt';
$SIG{ABRT} = 'interrupt';
$SIG{QUIT} = 'interrupt';
$SIG{TRAP} = 'interrupt';
$SIG{STOP} = 'interrupt';
$SIG{KILL} = 'interrupt';


#----------------------------- LOCAL CONSTANTS ---------------------------------


################################################################################
#
#                                 MAIN FUNCTION
#
################################################################################
#
# PRECONDITIONS:   
#
# POSTCONDITIONS:  n/a
#
# PARAMETERS:      -bt/ag baseline-tag       Baseline tag (eg. FL08_MACK_D13.29.35)
#                  -ba/se base-commit        Baseline commit (eg. tag, branch, sha-1)
#                  -ne/w new-commit          New commit (eg. tag, branch, sha-1)
#                  -br/anch dev-branch       Dev branch to use for checking changes into ClearCase
#                  -s/rc source-path         Source directory path (required option)
#                  -r/m element-list         File containing a list of CC elements to be removed
#                  -des/t destination-path   Destination directory path (required option)
#                  -n/oci | -c/ionly         No Checkin or Checkin Only
#                  -f/orce                   Suppress questions (for executing by other scripts)
#                  -deb/ug                   Use for debugging
#                  -dry/run                  Preview what commands will be executed
#                  -in/put                   Input file containing list of files to be imported
#                  -id/ent                   Allow checkin of identical versions
#                  -h/elp                    Print script usage
#
# RETURN VALUE:    n/a
#
#---------------------------- DETAILED DESCRIPTION -----------------------------
#
# You must have a view set to run this script. Your view config spec will be reset 
# to the released config_spec.txt modified to create a dev branch using the name
# provide at execution. Once complete, your config spec will be reset back to 
# it's original state. A backup copy is saved to: ~/.<view_tag_name>-cs.bkp
# 
# You must be in the root of a git repository or provide the git repository 
# path using the -src option. 
#
# This script will exit on failurs of element creations, and can be run-run 
# after a failure has been encountered and the issue resolved. It will create file 
# ~/.ClearCase_import_restart-$tag (where $tag = your view tag name) that contains
# all remaining files to be imported into clearcase. 
#
# You view should be free of view priviate files. Any checked out files in your view
# will be checked in by this script.
# 
# The script will NOT exit on failures during the checkin process. Any failed
# check-ins will be printed at the end. After correcting the issues you can
# rerun the script using the -cionly option. Likely check-in failures will be
# due to identical versions, you may use the -ident option to get around this. 
# However, the use of -ident is not recommended for normal use.
#
# You can choose to leave all dirs and elements checked out by using the -noci
# option. 
#
# You can run the script to checkin all elements checked out to the current view
# by using the -cionly option.
#
# The -force option will allow you to suppress the questions and run silently.
# Running -force will assume Yes for source folder confirmation
# and Yes for performing a restart.
#
#
################################################################################

#------------------------------ LOCAL VARIABLES --------------------------------

$|=1; # Flush I/O Buffers
my ($input, $rminput, $element, $dir, $cmd, $pdir, $srcFile, $srcDir, $tag);
my ($newCS, $csBkp, $base);
my (@contents, @rmcontents, @rncontents, @line, @ciErr, @coElems, @chkdIn);
my $dstDir = "/vobs";
my $CT = '/usr/atria/bin/cleartool';
my $HOME = "$ENV{'HOME'}";
my $me = basename($0);
my $ecount = 0;
my $rmecount = 0;
my $rnecount = 0;
my $ccount = 0;

# Variables set by Getopt for &arg_parser
use vars '$opt_debug';    # Run in debug mode
use vars '$opt_dryrun';   # Preview what will be done
use vars '$opt_src';      # Source folder
use vars '$opt_force';    # Suppress all confirmations
use vars '$opt_noci';     # Do not check in
use vars '$opt_cionly';   # Check in only
use vars '$opt_ident';    # Allow check in identical elements
use vars '$opt_print';    # Print config spec example
use vars '$opt_help';     # Print script usage
use vars '$opt_inp';      # Input file
use vars '$opt_rm';       # Remove CC elements
use vars '$opt_btag';     # Baseline tag
use vars '$opt_base';     # Baseline commit
use vars '$opt_new';      # New commit
use vars '$opt_branch';   # Dev branch to use


# Execute argument parser
&arg_parser();
my $restartFile = "$HOME" . "/.ClearCase_import_restart-" . "$tag";
my $rmrestartFile = "$HOME" . "/.ClearCase_remove_restart-" . "$tag";
my $rnrestartFile = "$HOME" . "/.ClearCase_rename_restart-" . "$tag";

#------------------------------------ Main -------------------------------------


# Verify Home dir is writable for restart files
   if (! -W $HOME) {
      die BOLD, RED, "Error: $me - Cannot write to HOME directory \"$ENV{'HOME'}\"\n", RESET;
   }

# Confirm source and destination dirs
   if ($opt_rm) {
      print "Element removal file list: $opt_rm\n";
   } elsif ($opt_inp) {
      print "Input file: $opt_inp\n";
      print "Source directory: $srcDir\n";
   } elsif ($opt_cionly) {
      print "Perform checkin of ClearCase elements only\n";
   } else {
      print "Source directory: $srcDir\n";
   }
   print BOLD, BLUE, "Running with debug turned on.\n", RESET if ($opt_debug);
   print BOLD, BLUE, "Running in preview mode, no commands will be executed.\n", RESET if ($opt_dryrun);
   #if (! $opt_force) {
   #   if (! &yes_or_no("Is the source directory correct:  [y/n]? ")) {
   #      exit 1;
   #   }
   #}
   print "\n";

# Debug stuff
   &date("Start Time") if ($opt_debug); 

# Perform check-in only
   if ($opt_cionly) {
      &date("Perfoming check-in only") if ($opt_debug);
      &setCS();
      &checkIn();
      &date("End Time") if ($opt_debug);
      &checkinErr();
   }


# Get source files

   if ( (-e $restartFile) || (-e $rmrestartFile) || (-e $rnrestartFile) ) {
      &date("Restart file found\n") if ($opt_debug); 
         
      # Verify if you want to restart
      if (!$opt_force && &yes_or_no("Restart file found, would you like to restart where your last import left off:  [y/n]? ") == 0) {
         if ( &yes_or_no("\nDo you want to remove following restart file(s):\n\t$restartFile\n\t$rmrestartFile\n\t$rnrestartFile\n\n  [y/n]? "))
         {
            unlink($restartFile)   if -e $restartFile;
            unlink($rmrestartFile) if -e $rmrestartFile;
            unlink($rnrestartFile) if -e $rnrestartFile;
            print "\nPlease clean your view to run a new full import again.\n\n";
         }
         
         exit 0;
      }
      
      if ( -e $restartFile) {
         open (RF, "<$restartFile") || die "Unable to open $restartFile: $!";
            while ( <RF> ) {
               push @contents, [ split ];
            }
         close (RF);
         @contents = sort { $a->[0] cmp $b->[0] } @contents;   # ASCII-betical sort
         chomp (@contents);
         unlink($restartFile);
         $ecount = @contents;
      }

      if ( -e $rmrestartFile) {
         @rmcontents = `cat $rmrestartFile`;
         @rmcontents = sort { $a cmp $b } @rmcontents;   # ASCII-betical sort
         chomp (@rmcontents);
         unlink($rmrestartFile);
         $rmecount = @rmcontents;
      }
      
      if ( -e $rnrestartFile) {
         open (RNRF, "<$rnrestartFile") || die "Unable to open $rnrestartFile: $!";
            while ( <RNRF> ) {
               push @contents, [ split ];
            }
         close (RNRF);
         @rncontents = sort { $a->[0] cmp $b->[0] } @rncontents;   # ASCII-betical sort
         chomp (@rncontents);
         unlink($rnrestartFile);
         $rnecount = @rncontents;
      }
   } elsif ( ($opt_inp || $opt_rm) ) {
      &date("No restart file found\n") if ($opt_debug); 
      &get_contents();
   } elsif ($opt_new) {
      &date("No restart file found\n") if ($opt_debug); 
      &gitDiff();
   }

# Setup config spec
   &setCS();

# Create brtype in vobs
   &createBrt(@contents, @rmcontents);
   
   
# Rename or move CC elements

   if ($#rncontents >= 0) {
      print "\n\nProcessing elements to be renamed or moved...\n";
      print "Number of renamed or moved elements processed in ClearCase..... [$rnecount]\n";
      foreach ((), @rncontents) {
         chomp;
       
         my $src_file = $_->[0];
         my $dst_file = $_->[1];
         
         $src_file =~ s/^\s+//gm; #remove leading white space
         $src_file =~ s/^\.\///gm; # remove leading ./
         $dst_file =~ s/^\s+//gm; #remove leading white space
         $dst_file =~ s/^\.\///gm; # remove leading ./
         
         my $src_elem = "$dstDir/" . "$src_file";
         my $dst_elem = "$dstDir/" . "$dst_file";
         
         if (! -e $src_elem) {
            print BOLD, GREEN, "Element does not exist: \t $src_elem\n", RESET;
            shift(@rncontents);
            next;
         } else {
            print "\n" if ($opt_debug);
            print BOLD, RED, " * $src_file --> $dst_file\n", RESET;
            my $elem;
            
            # Checkout src file parent dir
            @line = split(/\//, $src_file);
            $elem = pop(@line);
            $pdir = $src_elem;
            $pdir =~ s/\/$elem$//gm;
            checkout_dir($pdir);
            
            # create dst file dir
            @line = split(/\//, $dst_file);
            $elem = pop(@line);
            $pdir = $dst_elem;
            $pdir =~ s/\/$elem$//gm;
            
            if (-d $pdir) {
               checkout_dir($pdir);
            } else {
               create_dir($dst_file);
            }
            
            # Rename or move element
            $cmd = "$CT mv $src_elem $dst_elem";
            print "   $cmd<\n" if ($opt_debug);
            if (! $opt_dryrun) {
               print "   Renaming element\n";
               system("$cmd");
               &quit("Unable to rename element \"$src_elem\"") if ($?);
            }
         }
         shift(@rncontents);
         print "\n" if ($opt_debug);
      }
   }

# Remove CC elements

   if ($#rmcontents >= 0) {
      print "\n\nProcessing elements to be removed...\n";
      print "Number of deleted elements processed in ClearCase..... [$rmecount]\n";
      foreach ((), @rmcontents) {
         chomp;
         $_ =~ s/^\s+//gm; #remove leading white space
         $_ =~ s/^\.\///gm; # remove leading ./
         $element = "$dstDir/" . "$_";
         if (! -e $element) {
            print BOLD, GREEN, "Element does not exist: \t $element\n", RESET;
            shift(@rmcontents);
            next;
         } else {
            print "\n" if ($opt_debug);
            print BOLD, RED, " * $element\n", RESET;
            @line = split(/\//,$_);
            my $elem = pop(@line);
            $pdir = $element;
            $pdir =~ s/\/$elem$//gm;

               # Checkout parent dir
               checkout_dir($pdir);
               
               # If element is a directory, checkin it when it is empty. Otherwise it cannot be removed.
               if(-d $element)
               {
                 $cmd = "$CT ci -nc $element";
                 print "   $cmd<\n" if ($opt_debug);
                 if (! $opt_dryrun) {
                    &quit("Cannot checkin directory element \"$element\" since it is NOT empty") if glob "$element/*";
                    system("$cmd");
                    &quit("Unable to checkin directory element \"$element\"") if ($?);
                 }
               }

               # Remove element
               $cmd = "$CT rmname -nc $element";
               print "   $cmd<\n" if ($opt_debug);
               if (! $opt_dryrun) {
                  print "   Removing element\n";
                  system("$cmd");
                  &quit("Unable to remove element \"$element\"") if ($?);
               }
         }
         shift(@rmcontents);
         print "\n" if ($opt_debug);
      }
   }

 
# Create new CC elements

   if ($#contents >= 0) {
      print "\n\nProcessing elements to be added/modified...\n";
      print "Number of added/modified elements processed in ClearCase..... [$ecount]\n";
      foreach ((), 0..@contents-1) {
         chomp;
         #my $type = $contents[$_][1];
         #my $target = $contents[$_][2];
         my $type = $contents[0][1];
         my $target = $contents[0][2];

         # Skip .gitignore files
         if ($_ =~ /\.gitignore/) {
            print "   Skipping .gitignore file \"$_\"\n";
            shift(@contents);
            next;
         }

         $_ = "$contents[0][0]";
         $_ =~ s/^\.\///gm; # remove leading ./
         $element = "$dstDir/" . "$_";
         $srcFile = "$srcDir/" . "$_";
   
         # Verify if element exists in the VOB
         if (! -e $element) {
            print BOLD, MAGENTA, "Element does not exist: \t $element\n", RESET;
   
            # check for directory element, create if missing
            create_dir($_);
   
            # Create file element
            print "  Creating element...\n" if ($opt_debug);
   
            # Checkout parent dir
            checkout_dir($dir);
   
            # Is this a sym link?
            if ($type eq "l") {

               # Exit if no link target found
               if ($target eq "NULL") {
                  print "   NULL Target\n" if ($opt_debug);
                  &quit("No target found for symbolic link \"$element\"");
               }

               # Create sym link
               $cmd = "$CT ln -s -nc $target $element";
               print "   $cmd<\n" if ($opt_debug);
               if (! $opt_dryrun) {
                  print "   Creating symbolic link\n";
                  system("$cmd");
                  &quit("Unable to create symbolic link \"$element\"") if ($?);
               }
   
            } else { 

               # Create new element version
               $cmd = "$CT mkelem -nc $element";
               print "   $cmd\n" if ($opt_debug);
               if (! $opt_dryrun) {
                  print "   Creating file element\n";
                  system("$cmd");
                  &quit("Unable to create element \"$element\"") if ($?);
               }
   
               # Change element permissions
               $cmd = "$CT protect -chmod 775 $element";
               print "   $cmd\n" if ($opt_debug);
               if (! $opt_dryrun) {
                  print "   Setting file element permissions\n";
                  system("$cmd");
                  &quit("Unable to change element permissions for \"$element\"") if ($?);
               }
   
               # Copy in new file
               $cmd = "cp $srcFile $element";
               print "   $cmd\n" if ($opt_debug);
               if (! $opt_dryrun) {
                  print "   Copying new file from git to ClearCase\n";
                  system("$cmd");
                  &quit("Unable to copy source file \"$srcFile\" to element \"$element\"") if ($?);
               }
            }
   
         } else {
            print BOLD, GREEN, "Element exists: \t\t $element\n", RESET;

            # Is this a sym link?
            if ($type eq "l") {
               if ($target eq "NULL") {
                  print "   NULL Target\n" if ($opt_debug);
                  &quit("No target found for symbolic link \"$element\"");
               }

               if (-l $element) {
                  #print BOLD, RED, "Element is not a sym link and will be replaced with a sym link:\t $element\n", RESET;
                  print "  Replacing symbolic link target...\n" if ($opt_debug);
               } else {
                  print BOLD, RED, "Element is not a sym link and will be replaced with a sym link:\t $element\n", RESET;
                  print "  Replacing element with symbolic link...\n" if ($opt_debug);
               }

               @line = split(/\//,$_);
               my $elem = pop(@line);
               $pdir = $element;
               $pdir =~ s/\/$elem$//gm;

               # Checkout parent dir
               checkout_dir($pdir);

               # Remove element
               $cmd = "$CT rmname -nc $element";
               print "   $cmd<\n" if ($opt_debug);
               if (! $opt_dryrun) {
                  print "   Removing element\n";
                  system("$cmd");
                  &quit("Unable to remove element \"$element\"") if ($?);
               }

               # Create sym link
               $cmd = "$CT ln -s -nc $target $element";
               print "   $cmd<\n" if ($opt_debug);
               if (! $opt_dryrun) {
                  print "   Creating symbolic link\n";
                  system("$cmd");
                  &quit("Unable to create symbolic link \"$element\"") if ($?);
               }
   
            } else { 

            print "  Creating new version...\n" if ($opt_debug);
            # Checkout new element version
            $cmd = "$CT lsco -s -me -cview $element";
            print "   $cmd\n" if ($opt_debug);
            if ( ($opt_dryrun) || (! `$cmd`) ) {
               $cmd = "$CT co -nc $element";
               print "   $cmd\n" if ($opt_debug);
               if (! $opt_dryrun) {
                  print "   Checking out file element\n";
                  system("$cmd");
                  &quit("Unable to checkout element \"$element\"") if ($?);
               }
            } else {
               print "  Element already checked out...\n";
            }
               # Copy in new file
               $cmd = "cp $srcFile $element";
               print "   $cmd\n" if ($opt_debug);
               if (! $opt_dryrun) {
                  print "   Copying new file from git to ClearCase\n";
                  system("$cmd");
                  &quit("Unable to copy source file \"$srcFile\" to element \"$element\"") if ($?);
               }
            }
         }
   
         shift(@contents);
      }
   }


# Check-in elements
   if (! $opt_noci) {
      &date("Checking in elements") if ($opt_debug);
      &checkIn();
      &checkinErr();
   } else {
      &date("Not performing check-in") if ($opt_debug);
      print BOLD, BLUE, "\nWarning: $me - Elements were NOT checked in,\n", RESET if (! $opt_dryrun);
      print "Re-run $me with the ", BOLD, BLUE, "-cionly ", RESET, "option to execute the check-in process.\n" if (! $opt_dryrun);
      #print "\nNumber of added/modified elements processed in ClearCase.....\t $ecount\n";
      &resetCS();
   }

print "\n";
&date("End Time") if ($opt_debug);

#--------------------------------- Functions -----------------------------------

# --
# Argument parser
# --

sub arg_parser() {

   # We must have some arguments
   if (@ARGV == 0) {
      print BOLD, RED, "Error: $me - Missing arguments\n", RESET;
      &usage;
   }

   chomp(my $view = `$CT pwv -s`);
   if ( $view =~ /^\*\* NONE \*\*$/) {
      die BOLD, RED, "Error: $me - You must have a ClearCase view set to run this script\n", RESET;
   } else {
      $tag = $view;
   }

   # Process command-line parameters
    GetOptions("debug",
               "rm=s",
               "btag=s",
               "base=s",
               "new=s",
               "src=s",
               "branch=s",
               "inp=s",
               "force",
               "help",
               "dryrun",
               "noci",
               "cionly",
               "ident",
               "print") or &usage;

   # Print script usage
   if ($opt_help) {
      &usage();
   }

   # Print example config spec
   if ($opt_print) {
      &printCS();
   }

   # Can not have both -noci and -cionly
   if ( ($opt_noci) && ($opt_cionly) ) {
      print BOLD, RED, "Error: $me - Ambiguous arguments\n", RESET;
      &usage;
   }

   # Must have some specific options
   if ( ($opt_cionly) && ($opt_rm) ){
      print BOLD, RED, "Error: $me - Invalid arguments\n", RESET;
      &usage;
   } elsif ( (! $opt_btag) || (! $opt_branch) ) {
      print BOLD, RED, "Error: $me - Missing arguments\n", RESET;
      &usage;
   }

   # Verify if remove input file exists
   if ($opt_rm) {

      if (! -e $opt_rm ) {
         die BOLD, RED, "Error: $me - Input file \"$opt_rm\" not found\n", RESET;
      }

      $rminput = "$opt_rm";
   }

   # Verify source directory exists
   if ($opt_src) {

      if (! -d $opt_src ) {
         die BOLD, RED, "Error: $me - Source dir \"$opt_src\" not found\n", RESET;
      }
      $srcDir = "$opt_src";
   } else {
      if (! -d ".git" ) {
         die BOLD, RED, "Error: $me - You are not in the root of a Git repository, .git dir not found\n", RESET;
      }
      $srcDir = getcwd;
   }

   # Which baseline commit are we using
   if ($opt_base) {
      $base = $opt_base;
   } else {
      $base = $opt_btag;
   }

   # Verify baseline commit
   if (! `git rev-parse --quiet --verify $base`) {
      print BOLD, RED, "Error: $me - Baseline commit invalid\n", RESET;
      &usage;
   }

   # Verify new commit
   if ($opt_new) {
      if (! `git rev-parse --quiet --verify $opt_new`) {
         print BOLD, RED, "Error: $me - New commit invalid\n", RESET;
         &usage;
      }
   }

   # Verify if input file exists
   if ($opt_inp) {

      if (! -e $opt_inp ) {
         die BOLD, RED, "Error: $me - Input file \"$opt_inp\" not found\n", RESET;
      }

      $input = "$opt_inp";
   }

}

# --
# Script usage
# --

sub usage() {

print <<"EOF";
Usage: $me -bt/ag baseline-tag [-ba/se base-commit] -ne/w new-commit -br/anch dev-branch [ -s/rc source-path ]
                         [ -dr/yrun ] [ -no/ci ] [ -f/orce ] [ -de/bug ]

Usage: $me -bt/ag baseline-tag -in/put element-list [ -s/rc source-path ] -br/anch dev-branch
                         [ -dr/yrun ] [ -no/ci ] [ -f/orce ] [ -de/bug ]

Usage: $me -bt/ag baseline-tag -r/m element-list  [ -s/rc source-path ] -br/anch dev-branch
                         [ -dr/yrun ] [ -no/ci ] [ -f/orce ] [ -de/bug ]

Usage: $me -bt/ag baseline-tag -c/ionly [ -id/ent ] -br/anch dev-branch
                         [ -dr/yrun ] [ -f/orce ] [ -de/bug ]

Usage: $me [ -h/elp ]

====================================================================================================

                  -bt/ag baseline-tag       Baseline tag (eg. FL08_MACK_D13.29.35)
                  -ba/se base-commit        Baseline commit (eg. tag, branch, sha-1)
                  -ne/w new-commit          New commit (eg. tag, branch, sha-1)
                  -br/anch dev-branch       Dev branch to use for checking changes into ClearCase
                  -s/rc source-path         Source directory path (required option)
                  -r/m element-list         File containing a list of CC elements to be removed
                  -des/t destination-path   Destination directory path (required option)
                  -n/oci | -c/ionly         No Checkin or Checkin Only
                  -f/orce                   Suppress questions (for executing by other scripts)
                  -deb/ug                   Use for debugging
                  -dry/run                  Preview what commands will be executed
                  -in/put                   Input file containing list of files to be imported
                  -id/ent                   Allow checkin of identical versions
                  -h/elp                    Print script usage
EOF
exit;
}

# --
# Print config spec example
# --

sub printCS() {

print <<"EOF";

element * CHECKEDOUT
element * .../<DEV_BRANCH>/LATEST
element * <BASELINE_BRANCH> -mkbranch <DEV_BRANCH>
element * /main/LATEST -mkbranch <DEV_BRANCH>

###################################################
# Where <DEV_BRANCH> = the development branch of your choice
# Where <BASELINE_BRANCH> = the baseline branch for the target release

EOF
exit;
}


# --
# Date sub for debug option
# --

sub date() {

   # Get current time
   my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
   my $m = $mon + 1;
   my $y = $year += 1900;
   $mday = sprintf ("%02d",$mday);
   $m = sprintf ("%02d",$m);
   $y = sprintf ("%02d",$y);
   $hour = sprintf ("%02d",$hour);
   $min = sprintf ("%02d",$min);
   $sec = sprintf ("%02d",$sec);

   my $date = "$mday-" . "$m-" . "$y." . "$hour:" . "$min:" . "$sec";
   print "$date @_\n";

}

# --
# Yes or No question confirmation
# --

sub yes_or_no {

   my ($prompt) = @_;

   while (1) {
      print STDOUT $prompt;
      my ($answer) = scalar(<STDIN>);
      if ($answer =~ /y/i) {
         return(1);
      }
      elsif ($answer =~ /n/i) {
          return(0);
      }
   }
}

# --
# Quit script and print message to STDOUT
# --

sub quit() {
   print BOLD, RED, "Error: $me - @_\n", RESET;

   if ($#contents >= 0) {
      open (RESTART, ">$restartFile") || die "Unable to open $restartFile: $!";
         foreach my $r (0..@contents-1) {
            if (defined($contents[$r][2])) {
               print RESTART "$contents[$r][0] $contents[$r][1] $contents[$r][2]\n";
            } elsif ((defined($contents[$r][1])) && (!defined($contents[$_][2]))) {
               print RESTART "$contents[$r][0] $contents[$r][1] NULL\n";
            } else {
               print RESTART "$contents[$r][0] NULL NULL\n";
            }
         }
      close (RESTART);
   }

   if ($#rmcontents >= 0) {
      open (RMRESTART, ">$rmrestartFile") || die "Unable to open $rmrestartFile: $!";
         foreach (@rmcontents) {
            chomp;
            $_ =~ s/^\s+//gm; #remove leading white space
            print RMRESTART "$_\n";
         }
      close (RMRESTART);
   }
   
   if ($#rncontents >= 0) {
      open (RNRESTART, ">$rnrestartFile") || die "Unable to open $rnrestartFile: $!";
         foreach (@rncontents) {
            chomp;
            $_ =~ s/^\s+//gm; #remove leading white space
            print RNRESTART $_->[0] . " " . $_->[1] . "\n";
         }
      close (RNRESTART);
   }

   &resetCS();
   &date("End Time") if ($opt_debug);
   exit 1;
}

# --
# Get file contents from source directory
# --

sub get_contents() {

   if ($input) {
      open (IN, "<$input") || die "Unable to open $input: $!";
         while ( <IN> ) {
            push @contents, [ split ];
         }
      close (IN);
      foreach (0..@contents-1) {
         if (!defined($contents[$_][1])) {
            $contents[$_][1] = "NULL";
            $contents[$_][2] = "NULL";
         } elsif (!defined($contents[$_][2])) {
            $contents[$_][2] = "NULL";
         }
      }
      @contents = sort { $a->[0] cmp $b->[0] } @contents;   # ASCII-betical sort
      chomp (@contents);
      $ecount = @contents;
   }

   if ($rminput) {
      open (IN, "<$rminput") || die "Unable to open $input: $!";
         @rmcontents = <IN>;
      close (IN);
      @rmcontents = sort { $a cmp $b } @rmcontents;   # ASCII-betical sort
      chomp (@rmcontents);
      $rmecount = @rmcontents;
   }
}

# --
# Perform ClearCase checkin
# --

sub checkIn() {

   print "\n\nChecking in elements...\n";
   $cmd = "$CT lsco -s -me -cview -avobs";
   @coElems = `$cmd`;
   $ccount = @coElems;
   if (@coElems) {
      chomp @coElems;
      @coElems = sort { $b cmp $a } @coElems;   # ASCII-betical sort
   } else {
      print BOLD, BLUE, "\nWarning: $me - no checkouts found.\n", RESET;
   }

   foreach (@coElems) {
      # Checkin element
      if (! $opt_ident) {
         $cmd = "$CT ci -nc $_";
      } else {
         $cmd = "$CT ci -nc -ident $_";
      }
      print BOLD, GREEN, "Element: \t $_\n", RESET;
      print "   $cmd\n" if ($opt_debug);

      if (! $opt_dryrun) {
         system("$cmd");

         # Save elements for later on error
         if ($?) {
            print BOLD, RED, "Error: $me - Checkin failed for \"$_\"\n", RESET;
            push(@ciErr,"$_" . "\n");
         } else {
            push(@chkdIn,"$_" . "\n");
         }
      }

   }

   return @coElems;

}

# --
# Print failed checkin elements to STDOUT
# --

sub checkinErr() {

   if (@ciErr) {
      &printList(@chkdIn) if (! $opt_dryrun);
      print BOLD, RED, "\nError: $me - Checkin failed for the files listed below...\n", RESET;
      print "       Fix the issue and re-run $me with the ", BOLD, BLUE, "-cionly ", RESET, "option to complete the check-in process.\n";
      print "\n @ciErr\n\n";
      &resetCS();
      &date("End Time") if ($opt_debug);
      exit 1;
   } else {
      print "\nNumber of elements & directories checked-in to ClearCase..... [$ccount]\n";
      #&printList(@chkdIn) if (! $opt_dryrun);
      &resetCS();
      &date("End Time") if ($opt_debug);
      exit 0;
   }

}

# --
# Print version list 
# --

sub printList() {

   print "\n\nChecked in element list...\n";
   foreach (@_) {
      $cmd = "$CT desc -fmt \"%n\n\" $_";
      system("$cmd");
   }
   print "\n";

}

# --
# Get file/commit diff between commits
# --

sub gitDiff() {

   my @list;
   my @rename_exclude_list;
   
   # Get delta list of rename cases
   $cmd = "git diff -M100% --summary $base $opt_new";
   @list = `$cmd`;
   @list = sort { $a cmp $b } @list;   # ASCII-betical sort
   
   foreach (@list) {
      chomp;
      next unless /rename.*\(100%\)/;
      
      my $pref = "";
      my $suff = "";
      my $changed;
      my $src_sec = "";
      my $dst_sec = "";
      
      if (/rename\s+(\S*){(.*)}(\S*)\s+\(100%\)/) {
         $pref = $1 if $1;
         $changed = $2;
         $suff = $3 if $3;
      }
      
      if ($changed =~ /(\S*)\s+=>\s+(\S*)/) {
         $src_sec = $1 if $1;
         $dst_sec = $2 if $2;
      }
      
      my $src_file = $pref.$src_sec.$suff;
      $src_file =~ s#//#/#;
      my $dst_file = $pref.$dst_sec.$suff;
      $dst_file =~ s#//#/#;
      
      push (@rncontents, [$src_file, $dst_file]);
      push @rename_exclude_list, $src_file;
      push @rename_exclude_list, $dst_file;
   }

   # Get delta list of repos
   $cmd = "git diff --name-only $base $opt_new";
   @list = `$cmd`;
   @list = sort { $a cmp $b } @list;   # ASCII-betical sort

   print "[INFO]****Files to be synced are @list";
   # We must have some diff between commits
   if (@list == 0) {
      print BOLD, RED, "Warning: $me - No difference found between commits - $base ~ $opt_new\n\n", RESET;
      exit 0;
   }

   foreach (@list) {
      chomp;
      print "Changed file: \"$_\"\n" if ($opt_debug);
      next if $_ ~~ @rename_exclude_list;
      
      if (-e $_) {
         # Get file type and store in array of arrays
         if (-l $_) {
           chomp(my $target = `find $_ -prune -printf "%l\n"`);
           print "      File type is \"link\"\n" if ($opt_debug);
           print "      Link target is: \"$target\"\n" if ($opt_debug);
           push (@contents, ["$_", "l", "$target"]);
         } elsif (-d $_) {
           print "      File type is \"directory\"\n" if ($opt_debug);
           push (@contents, ["$_", "d", "NULL"]);
         } else {
           print "      File type is \"plain file\"\n" if ($opt_debug);
           push (@contents, ["$_", "f", "NULL"]);
         }
      } else {
        print "      File type is \"REMOVED\"\n" if ($opt_debug);
        push(@rmcontents, "$_" . "\n");
      }
   }
   
   print "\n" if ($opt_debug);
   
   # Check if any dir needs to be removed as well 
   my @rmdirs;
   
   foreach (@rmcontents, @rename_exclude_list)
   {
     chomp;
     my @dir_sections = split "/", $_;
     pop @dir_sections;    # Pop out the file element, leaving dir sections only
         
     while(@dir_sections)
     {
       my $dir = join '/', @dir_sections;
       push @rmdirs, $dir unless -d $dir;
       pop @dir_sections;
     }
   }
   
   @rmdirs = uniq(@rmdirs);
   @rmdirs = sort { $b cmp $a } @rmdirs;   # Reversed ASCII-betical sort
   push @rmcontents, @rmdirs;
   
   $ecount   = @contents;
   $rmecount = @rmcontents;
   $rnecount = @rncontents;
}

# --
# Set config spec
# --

sub setCS() {

   $newCS = "$HOME/.new_cs.txt";
   $csBkp = "$HOME" . "/." . "$tag" . "-cs.bkp";
   print "Updating config spec...\n";
   print "   New config spec is: $newCS\n";
 
   # Get new config spec
   $cmd = "$CT find /vobs/scm_sandbox/ConfigSpec.txt -ver \"lbtype($opt_btag)\" -print";
   print "[*info*] find cd cmd is $cmd \n\n";
   chomp(my $baseCS = `$cmd`);
   print "   Baseline config spec: \"$baseCS\"\n";

   if (! $baseCS) {
      print BOLD, RED, "\nError: $me - Can not find baseline config spec for \"$opt_btag\"\n", RESET;
      exit 1;
   }

   open (FH, "$baseCS") || die "Unable to open $baseCS: $!";
      my @baseCS = <FH>;
      chomp @baseCS;
   close (FH);

   # Backup config spec
   print "   Backup config spec: \"$csBkp\"\n";
   $cmd = "$CT catcs > $csBkp";
   print "   $cmd\n" if ($opt_debug);

   #if (! $opt_dryrun) {
      system("$cmd");
      &quit("Unable to backup view config spec") if ($?);
   #}

   # Update config spec
   open (CS, ">$newCS") || die "Unable to open $baseCS: $!";

      my $n = @baseCS;
      my $i = 0;
      for ($i = 0; $i <= $n; $i++) {
         if ($i == 0) {
            print CS "element * CHECKEDOUT\n" . "element * .../$opt_branch/LATEST\n\n";
         }

         if (defined($baseCS[$i])) {
            if ($baseCS[$i] =~ /^(element\s\*\sCHECKEDOUT\s*)$/) {next;}
            #$baseCS[$i] =~ s/^(element\s\*\sCHECKEDOUT\s*)$//g;
            $baseCS[$i] =~ s/^(element\s.*)/$1 -mkbranch $opt_branch/g;
            print CS "$baseCS[$i]\n";
         }

         if ($i == $n) {
            print CS "element * /main/LATEST -mkbranch $opt_branch\n";
         }

      }

   close (CS);

   # Set config spec

   print "Setting new config spec: \"$newCS\"\n";
   $cmd = "$CT setcs $newCS";
   print "   $cmd\n" if ($opt_debug);
   
   if (! $opt_dryrun) {
      system("$cmd");
      &quit("Unable to set config spec") if ($?);
   }

}

# --
# Reset config spec
# --

sub resetCS() {

   # Set config spec back to original

   print "\n\nSetting config spec back to original: \"$csBkp\"\n";
   $cmd = "$CT setcs $csBkp";
   print "   $cmd\n" if ($opt_debug);
   
   if (! $opt_dryrun) {
      system("$cmd");
      &quit("Unable to reset config spec") if ($?);
   }
   print "\n";

}

# --
# Create brtype
# --

sub createBrt() {

   my @vobTags;
   my @line;
   chomp @_;

   # Get list of vob tags
   foreach (@_) {
      if (ref eq "ARRAY") { # Dereference array
         @line = split(/\//,$_->[0]);
      } else {
         @line = split(/\//,$_);
      }
      my $tag = shift(@line);
      push(@vobTags, "$dstDir" . "/" . "$tag");
   }
   @vobTags = uniq(@vobTags);

   # Create brtype in vobs
   print "\n\nCreating brtype in vobs\n";
   foreach (@vobTags) {
      chomp;
      print BOLD, GREEN, "VOB tag: $_\n", RESET;
      # Verify if tag exists
      $cmd = "$CT lstype -s brtype:$opt_branch\@$_ 2> /dev/null";
      print "   $cmd\n" if ($opt_debug);

      if ( ($opt_dryrun) || (! `$cmd`) ) {

         # create the brtype
         $cmd = "$CT mkbrtype -nc $opt_branch\@$_";
         print "   $cmd\n" if ($opt_debug);

         if (! $opt_dryrun) {
            system("$cmd");
            &quit("Can not crate brtype") if ($?);
         }
      }
   }

}

# --
# Checkout directory
# --

sub checkout_dir {
   my ($dir) = @_;
   
   $cmd = "$CT lsco -s -me -cview -d $dir";
   print "   $cmd<\n" if ($opt_debug);
   if ( ($opt_dryrun) || (! `$cmd`) ) {
      # Checkout parent dir
      $cmd = "$CT co -nc $dir";
      print "   $cmd<\n" if ($opt_debug);
      if (! $opt_dryrun) {
         print "   Checking out parent directory\n";
         system("$cmd");
         &quit("Unable to checkout \"$dir\"") if ($?);
      }
   }
}

# --
# Create directory
# --

sub create_dir {
   
   my ($target_file) = @_;
   
   @line = split(/\//, $target_file);
   my $c = @line;
   my $i = 0;
   $dir = "$dstDir";

   # loop through each directory in element path
   for ($i = 0; $i < $c-1; $i++) {
      $pdir = "$dir";
      $dir = "$dir/" . "$line[$i]";
      if (! -d $dir) {
         print "  Creating directory...\n" if ($opt_debug);

         # Checkout parent dir
         checkout_dir($pdir);

         # Create dir element
         $cmd = "$CT mkdir -nc $dir";
         print "   $cmd<\n" if ($opt_debug);
         if (! $opt_dryrun) {
            print "   Creating directory element\n";
            system("$cmd");
            &quit("Unable to create dir element \"$dir\"") if ($?);
         }

         # Change dir permissions
         $cmd = "$CT protect -chmod 775 $dir";
         print "   $cmd<\n" if ($opt_debug);
         if (! $opt_dryrun) {
            print "   Setting directory element permissions\n";
            system("$cmd");
            &quit("Unable to change dir permissions for \"$dir\"") if ($?);
         }
      }
   }
}

# --
# Catch interrupts
# --

sub interrupt {

   my($signal)=@_;
   print BOLD, RED, "\nCaught Interrupt\: $signal $!\n", RESET;
   &quit("Exiting due to interrupt");

}

################################################################################
##
##                              HISTORY TEMPLATE
##
#################################################################################
##
## Date        Name              Discrepancy Number(s)    Notes
## --------    -----------       -----------------------  ------------------------------
## 10/15/2014  Eric Windfelder                            Initial creation.
## 11/12/2014  Eric Windfelder                            Added support for symbolic links
## 11/12/2014  Eric Windfelder                            Added new -base option
## 12/09/2015  Botter Bao                                 Added support for mv operation
## Next change ...
##
#################################################################################
#
