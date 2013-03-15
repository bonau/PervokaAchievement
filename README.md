PervokaAchievement
==================

An configurable achievement system for redmine, a fantastic project management web application.

Every single achievement should be written in code, which is part of this achievement system.


Install
-------

Simply copy this project to your own redmine directory:

    git clone git://github.com/bonau/PervokaAchievement.git /tmp/pervoka_achievement
    cp -a /tmp/pervoka_achievement /path/to/redmine/plugins/pervoka_achievement

or use it as a submodule:

    git submodule add git://github.com/bonau/PervokaAchievement.git plugins/pervoka_achievement
    git add .gitmodule plugins/pervoka_achievement
    git commit -m 'add pervoka achievement plugin'
    git submodule init # optional

Roadmap
-------

### v0.1
Basic achievement system implemented.

### v0.4 (not implemented yet)
Client-based achievement will be supported.

### v0.7 (not implemented yet)
One or more notification system will be involved.

