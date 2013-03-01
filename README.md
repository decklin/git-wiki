Decklin's git-wiki
==================

Everyone needs a fork of git-wiki; here's mine. It was originally done
in 2009 and then rebased and cleaned up a bit in 2013. The main
differences are:

  * It doesn't use a separate repository to hold the wiki; you clone
    git-wiki and then store your pages in that repo! From there,
    changes to the code can be merged from upstream or cherry-picked
    back. Because of this, you don't have to configure a repository path.

  * You don't have to use the branch 'master'; git-wiki always reads and
    commits to the current branch. (You may prefer to keep all your real
    pages in a branch, and have master just be a tracking branch.)

  * Wiki links use [[Brackets, Like... This]], and generate a link to
    (e.g.) "brackets-like-this". You *can* create a page with
    characters other than [a-z0-9-], but you won't be able to link to
    it as easily.

  * The default extension for Markdown files is ".md".

  * There's a basic stylesheet included. The views themselves are more
    spartan, but since they are a part of your wiki's repository, you
    are encouraged to edit them.

  * It's a classic style application, and does not need to be run with a
    config.ru. If you need one, you can use the [instructions in
    Sinatra's README][configru].

A few minor features have been added:

  * You can enter a commit message when editing a page. If you don't,
    the default message only denotes that the commit was made from the
    web interface.

  * Page histories are viewable with the query param `view=log`.

Git-wiki was designed and written by Simon Rozet. He did the hard work, I
just fiddled with the chrome a bit. The original README contains a wealth
of additional information.

[configru]: http://www.sinatrarb.com/intro#Using%20a%20Classic%20Style%20Application%20with%20a%20config.ru

Installation and Use
--------------------

This git-wiki requires Ruby 1.9. Here's how to create a new wiki and run it:

    git clone git-wiki my-wiki
    cd my-wiki
    bundle install
    ./git-wiki.rb # and point browser to http://localhost:4567/

Configuration
-------------

At the end of git-wiki.rb is a `configure` block (which applies to all
environments). You can edit settings here, or add additional blocks to
set different wiki repositories for development/testing/production.

Caveats
-------

Because we use Grit by modifying the workdir and then calling `git
add`, git-wiki must be run with a non-bare wiki repo. If you want to
clone this repo and then push to it, you should read the [Git FAQ
entry][faq] about the perils of pushing to a repo with a checked-out
workdir.

In practice, you will hopefully never edit the workdir of the "live"
repo directly, so ensuring that receive.denyNonFastForwards is turned
on and adding a post-update hook to reset the index is a reasonable
(if not very clean) work-around.

[faq]: http://git.or.cz/gitwiki/GitFaq#push-is-reverse-of-fetch

License
-------

    Copyright (C) 2008 Simon Rozet <simon@rozet.name>
    Copyright (C) 2009, 2013 Decklin Foster <decklin@red-bean.com>

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                       Version 2, December 2004

    Everyone is permitted to copy and distribute verbatim or modified
    copies of this license document, and changing it is allowed as long
    as the name is changed.

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
      TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

     0. You just DO WHAT THE FUCK YOU WANT TO.
