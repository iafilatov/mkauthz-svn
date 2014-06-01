mkauthz-svn
===========

A set of tools to delegate Subversion access control to project managers.

*Note: mkauthz-svn was written before DAV SVN Apache module had AuthzSVNReposRelativeAccessFile. And now Subversion can [store the authz file in the repository itself](https://subversion.apache.org/docs/release-notes/1.8.html#in-repo-authz), so you should probably just use that.*


About
-----

In an environment where you manage a Subversion server holds repositories of different teams, each team may want to restrict access too their projects. Sometimes you just can't be bothered to add new users, remove old ones and modify rules all the time. mkauthz-svn allows you to delegate this task to the teams themselves.


How it works
------------

1. You write a base [authz](http://svnbook.red-bean.com/nightly/en/svn.serverconfig.pathbasedauthz.html) file once. It must contain default rules for each project. For example "only the manager has write access". This way you only need to edit it if the manager changes.

2. The manager writes authz file for his project and pushes it to the root of his project in Subversion.

3. mkauthz-svn combines the base file with all per-project files and puts the combined rules file where the server can find it.


Dependencies
------------

[Config::Abstract::Ini](http://search.cpan.org/~avajadi/Config-Abstract-0.13/Ini/Ini.pm) Perl module by Eddie Olsson <ewt@avajadi.org>.
