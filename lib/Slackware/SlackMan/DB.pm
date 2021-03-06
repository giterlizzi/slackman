package Slackware::SlackMan::DB;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION = 'v1.4.1';
  @ISA     = qw(Exporter);

  @EXPORT_OK = qw{
    dbh
    db_init
    db_wipe_table
    db_wipe_tables
    db_insert
    db_bulk_insert
    db_compact
    db_meta_get
    db_meta_set
    db_meta_delete
    db_reindex
    db_drop
    db_check
    $dbh
  };

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use DBI;

use Slackware::SlackMan;
use Slackware::SlackMan::Utils qw(:all);

use constant SLACKMAN_SCHEMA_VERSION => 4;

use constant SLACKMAN_PACKAGES_TABLE => qq/CREATE TABLE IF NOT EXISTS "packages" (
  "id"                INTEGER PRIMARY KEY,
  "repository"        VARCHAR,
  "priority"          INTEGER,
  "excluded"          BOOL,
  "name"              VARCHAR,
  "package"           VARCHAR,
  "version"           VARCHAR,
  "arch"              VARCHAR,
  "build"             INTEGER,
  "tag"               VARCHAR,
  "category"          VARCHAR,
  "summary"           VARCHAR,
  "description"       TEXT,
  "mirror"            VARCHAR,
  "location"          VARCHAR,
  "required"          VARCHAR,
  "conflicts"         VARCHAR,
  "suggests"          VARCHAR,
  "size_compressed"   INTEGER,
  "size_uncompressed" INTEGER,
  "checksum"          VARCHAR)/;

use constant SLACKMAN_PACKAGES_INDEX => qq/CREATE INDEX IF NOT EXISTS "packages_idx" ON "packages" (
  "name"              ASC,
  "package"           ASC,
  "arch"              ASC,
  "status"            ASC,
  "repository"        ASC)/;

use constant SLACKMAN_HISTORY_TABLE => qq/CREATE TABLE IF NOT EXISTS "history" (
  "id"                INTEGER PRIMARY KEY,
  "name"              VARCHAR,
  "package"           VARCHAR,
  "version"           VARCHAR,
  "arch"              VARCHAR,
  "build"             INTEGER,
  "tag"               VARCHAR,
  "status"            VARCHAR,
  "timestamp"         DATETIME,
  "upgraded"          DATETIME,
  "summary"           VARCHAR,
  "description"       TEXT,
  "size_compressed"   INTEGER,
  "size_uncompressed" INTEGER)/;

use constant SLACKMAN_HISTORY_INDEX => qq/CREATE INDEX IF NOT EXISTS "history_idx" ON "history" (
  "name"              ASC,
  "package"           ASC,
  "arch"              ASC,
  "status"            ASC)/;

use constant SLACKMAN_MANIFEST_TABLE => qq/CREATE TABLE IF NOT EXISTS "manifest" (
  "id"                INTEGER PRIMARY KEY,
  "repository"        VARCHAR,
  "name"              VARCHAR,
  "package"           VARCHAR,
  "version"           VARCHAR,
  "arch"              VARCHAR,
  "build"             INTEGER,
  "tag"               VARCHAR,
  "files"             TEXT)/;

use constant SLACKMAN_MANIFEST_INDEX => qq/CREATE INDEX IF NOT EXISTS "manifest_idx" ON "manifest" (
  "directory"         ASC,
  "file"              ASC)/;

use constant SLACKMAN_CHANGELOGS_TABLE => qq/CREATE TABLE IF NOT EXISTS "changelogs" (
  "id"                INTEGER PRIMARY KEY,
  "repository"        VARCHAR,
  "timestamp"         DATETIME,
  "name"              VARCHAR,
  "package"           VARCHAR,
  "version"           VARCHAR,
  "arch"              VARCHAR,
  "build"             INTEGER,
  "tag"               VARCHAR,
  "category"          VARCHAR,
  "status"            VARCHAR,
  "description"       VARCHAR,
  "announce"          TEXT,
  "security_fix"      BOOL,
  "issues"            VARCHAR)/;

use constant SLACKMAN_METADATA_TABLE => qq/CREATE TABLE IF NOT EXISTS "metadata" (
  "id"                INTEGER PRIMARY KEY,
  "key"               VARCHAR,
  "value"             VARCHAR)/;

use constant SLACKMAN_SCHEMA => {
  'packages'     => SLACKMAN_PACKAGES_TABLE,
  'metadata'     => SLACKMAN_METADATA_TABLE,
  'changelogs'   => SLACKMAN_CHANGELOGS_TABLE,
  'history'      => SLACKMAN_HISTORY_TABLE,
  'manifest'     => SLACKMAN_MANIFEST_TABLE,
  'history_idx'  => SLACKMAN_HISTORY_INDEX,
  'packages_idx' => SLACKMAN_PACKAGES_INDEX,
  'manifest_idx' => SLACKMAN_MANIFEST_INDEX,
};

use constant SLACKMAN_TABLES  => qw( packages metadata changelogs history manifest );
use constant SLACKMAN_INDEXES => qw( history_idx packages_idx manifest_idx );

# Override built-in DBI module subroutines for log all SQL statements
BEGIN {

  if ( $slackman_conf->{'logger'}->{'category'} =~ /sql/ ) {

    no strict;
    no warnings;

    sub _log {

      my ($sub, $dbh, $stmt, $bind) = @_;
      my $message = "DBI::$sub - $stmt";
      my $i = 0;

      $message =~ s{\?}{$dbh->quote($bind->[$i++])}eg;
      logger->debug($message);

    }

    my $orig_execute            = \&DBI::st::execute;
    my $orig_selectall_arrayref = \&DBI::db::selectall_arrayref;
    my $orig_selectcol_arrayref = \&DBI::db::selectcol_arrayref;
    my $orig_selectall_hashref  = \&DBI::db::selectall_hashref;
    my $orig_selectrow_arrayref = \&DBI::db::selectrow_arrayref;
    my $orig_selectrow_array    = \&DBI::db::selectrow_array;
    my $orig_selectrow_hashref  = \&DBI::db::selectrow_hashref;
    my $orig_do                 = \&DBI::db::do;

    *DBI::st::execute = sub {
      my ($sth, @bind) = @_;
      _log("execute", $sth->{Database}, $sth->{Statement}, \@bind);
      return $orig_execute->($sth, @bind);
    };

    *DBI::db::selectall_arrayref = sub {
      my ($dbh, $stmt, $attr, @bind) = @_;
      _log("selectall_arrayref", $dbh, $stmt, \@bind);
      return $orig_selectall_arrayref->($dbh, $stmt, $attr, @bind);
    };

    *DBI::db::selectcol_arrayref = sub {
      my ($dbh, $stmt, $attr, @bind) = @_;
      _log("selectcol_arrayref", $dbh, $stmt, \@bind);
      return $orig_selectcol_arrayref->($dbh, $stmt, $attr, @bind);
    };

    *DBI::db::selectall_hashref = sub {
      my ($dbh, $stmt, $key_field, $attr, @bind) = @_;
      _log("selectall_hashref", $dbh, $stmt, \@bind);
      return $orig_selectall_hashref->($dbh, $stmt, $key_field, $attr, @bind);
    };

    *DBI::db::selectrow_arrayref = sub {
      my ($dbh, $stmt, $attr, @bind) = @_;
      _log("selectrow_arrayref", $dbh, $stmt, \@bind);
      return $orig_selectrow_arrayref->($dbh, $stmt, $attr, @bind);
    };

    *DBI::db::selectrow_array = sub {
      my ($dbh, $stmt, $attr, @bind) = @_;
      _log("selectrow_array", $dbh, $stmt, \@bind);
      return $orig_selectrow_array->($dbh, $stmt, $attr, @bind);
    };

    *DBI::db::selectrow_hashref = sub {
      my ($dbh, $stmt, $attr, @bind) = @_;
      _log("selectrow_hashref", $dbh, $stmt, \@bind);
      return $orig_selectrow_hashref->($dbh, $stmt, $attr, @bind);
    };

    *DBI::db::do = sub {
      my ($dbh, $stmt, $attr, @bind) = @_;
      _log("do", $dbh, $stmt, \@bind);
      return $orig_do->($dbh, $stmt, $attr, @bind);
    };

  }

}

our $dbh = dbh();

sub dbh {

  my $dsn = sprintf('dbi:SQLite:dbname=%s/db.sqlite', $slackman_conf->{'directory'}->{'lib'});

  our $dbh = DBI->connect($dsn, '', '', {
    PrintError       => 1,
    RaiseError       => 1,
    AutoCommit       => 1,
    FetchHashKeyName => 'NAME_lc',
  }) or die ("Can't open database!");

  $dbh->do('PRAGMA foreign_keys = ON');
  $dbh->do('PRAGMA synchronous  = OFF');
  $dbh->do('PRAGMA journal_mode = MEMORY');
  $dbh->do('PRAGMA temp_store   = MEMORY');
  $dbh->do('PRAGMA cache_size   = 800000');


  $dbh->sqlite_create_function('version_compare', -1, sub {
    my ($old, $new) = @_;
    return versioncmp($old, $new);
  });


  # Implement REGEXP function
  # (see "The LIKE, GLOB, REGEXP, and MATCH operators" in https://sqlite.org/lang_expr.html)
  #
  $dbh->sqlite_create_function('regexp', -1, sub {

    my ($string, $pattern) = @_;
    my ($matches) = ( $string =~ /$pattern/ );

    return $matches;

  });


  logger->debug("Connected to $dsn");

  db_check();

  return $dbh;

}

sub db_check {

  my $slackman_schema_version = (($dbh->selectrow_arrayref('PRAGMA user_version', undef))->[0]);

  # Init database if "user_version" pragma is not defined
  #
  unless ($slackman_schema_version) {
    db_init();
    $slackman_schema_version = SLACKMAN_SCHEMA_VERSION;
  }

  # Drop all table and index if schema version is less than SLACKMAN_SCHEMA_VERSION
  #
  if ( $slackman_schema_version < SLACKMAN_SCHEMA_VERSION ) {

    logger->debug(sprintf('Detected previous SlackMan schema version (actual: %s, required: %s)',
      $slackman_schema_version, SLACKMAN_SCHEMA_VERSION));

    logger->debug('Re-create SlackMan database');

    db_drop();
    db_compact();
    db_init();

  }

}

sub db_drop {

  foreach (SLACKMAN_INDEXES) {
    logger->debug(qq/Drop index "$_"/);
    $dbh->do("DROP INDEX $_");
  }

  foreach (SLACKMAN_TABLES) {
    logger->debug(qq/Drop table "$_"/);
    $dbh->do("DROP TABLE $_");
  }

}

sub db_init {

  foreach (SLACKMAN_TABLES) {
    logger->debug(qq/Init table "$_"/);
    $dbh->do(SLACKMAN_SCHEMA->{$_});
  }

  foreach (SLACKMAN_INDEXES) {
    logger->debug(qq/Init index "$_"/);
    $dbh->do(SLACKMAN_SCHEMA->{$_});
  }

  $dbh->do(sprintf('PRAGMA user_version = %s', SLACKMAN_SCHEMA_VERSION));

}

sub db_wipe_tables {

  foreach (SLACKMAN_TABLES) {
    db_wipe_table($_);
  }

}

sub db_wipe_table {
  logger->debug(qq/Wipe "$_" table/);
  $dbh->do("DELETE FROM $_");
}

sub db_insert {

  my ($table, $data) = @_;

  my $columns      = join( ', ', map { qq/'$_'/ } keys %$data );
  my $placeholders = join( ', ', map { qq/?/ }    keys %$data );
  my @values       = values %$data;
  my $query        = "INSERT INTO $table($columns) VALUES ($placeholders)";
  my $sth          = $dbh->prepare($query);

  $sth->execute(@values);

}

sub db_compact {
  logger->debug('Compact database');
  $dbh->do('PRAGMA VACUUM');
}

sub db_reindex {

  foreach (SLACKMAN_TABLES) {
    logger->debug(qq/Reindex "$_" table/);
    $dbh->do("REINDEX $_");
  }

  foreach (SLACKMAN_INDEXES) {
    logger->debug(qq/Reindex "$_" index/);
    $dbh->do("REINDEX $_");
  }

}

sub db_bulk_insert {

  my (%params) = @_;

  my $table   = $params{'table'};
  my $columns = $params{'columns'};
  my $values  = $params{'values'};

  my $n_rows  = scalar(@$values);

  logger->debug(qq/Insert $n_rows rows into "$table" table/);

  my $query = sprintf("INSERT INTO %s(%s) VALUES(%s)",
    $table,
    join(', ', @$columns),
    join(', ', map {qq/?/} @$columns)
  );

  $dbh->begin_work();

  my $sth = $dbh->prepare($query);

  foreach my $row (@$values) {
    $sth->execute(@$row);
  }

  $dbh->commit();

}

sub db_meta_get {

  my ($key) = @_;
  logger->debug(qq/Get key "$key" value/);

  return $dbh->selectrow_array(qq/SELECT value FROM metadata WHERE key = ?/, undef, $key);

}

sub db_meta_set {

  my ($key, $value) = @_;
  logger->debug(qq/Set key "$key" value "$value"/);

  $dbh->do(qq/DELETE FROM metadata WHERE key = ?/, undef, $key);
  $dbh->do(qq/INSERT INTO metadata(key, value) VALUES(?, ?)/, undef, $key, $value);

  return 1;

}

sub db_meta_delete {

  my ($key) = @_;

  logger->debug(qq/Delete key "$key"/);

  return $dbh->selectrow_array(qq/DELETE FROM metadata WHERE key = ?/, undef, $key);

}

1;
__END__

=head1 NAME

Slackware::SlackMan::DB - SlackMan DB module

=head1 SYNOPSIS

  use Slackware::SlackMan::DB qw(:all);

  db_bulk_insert(
    'table'   => 'foo',
    'columns' => [ 'foo', 'bar', 'baz' ],
    'values'  => [
      [1,2,3],
      [4,5,6]
    ],
  )

=head1 DESCRIPTION

DB module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head2 db_bulk_insert

=head2 db_compact

=head2 db_init

=head2 db_insert

=head2 db_meta_get

=head2 db_meta_set

=head2 db_reindex

=head2 db_reindex

=head2 db_wipe_table

=head2 db_wipe_tables

=head2 dbh

=head1 VARIABLES

=head2 $dbh

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::DB

You can also look for information at:

=over 4

=item * GitHub issues (report bugs here)

L<https://github.com/LotarProject/slackman/issues>

=item * SlackMan documentation

L<https://github.com/LotarProject/slackman/wiki>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2018 Giuseppe Di Terlizzi.

This module is free software, you may distribute it under the same terms
as Perl.

=cut
