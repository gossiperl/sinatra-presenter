# Sinatra presenter

Remote control your OS X Keynote presentations from your mobile device.

## Installation

Ensure that you have `ruby`, `gem` and `git` installed on your OS X. If not, use [homebrew](http://brew.sh/) to install these.

Ensure you have `bundler` gem installed. If not, execute:

    gem install bundler

Clone `sinatra-presenter` repository:

    git clone https://github.com/gossiperl/sinatra-presenter.git

Configure:

    cd sinatra-presenter
    bundle install

Start the application:

    ruby app.rb

The application will bind to `0.0.0.0` on port `4567`.

## Using

Place your Keynote files in the supplied `presos` directory.

Make sure your remote device (phone, tablet) is on the same network as your computer. Find out what's your computers' IP address, it will be one of:

    ifconfig | grep inet

On your mobile device go to:

    http://<computer-ip>:4567/

You should see something like this:

![App start screen][shot1]

Choose the presentation from the list. If Keynote isn't started, it should start now, presentation should be loaded and go into slideshow mode.

After a short while your screen should look similar to this:

![Presentation loaded][shot2]

Control the presentation with the buttons. To stop the presentation, pull the screen up, the `Stop presenting` button will appear.

![Stop presenting][shot3]

If you confirm, Keynote should close.

## Issues

This is a very, very version. There's a number of issues, either known or unknown. Check [the list of known issues](https://github.com/gossiperl/sinatra-presenter/issues) or report a new one.

Pull requests welcomed!

## License

Unless stated otherwise within an embedded module, LGPLv3.

[shot1]: public/images/shot1.png
[shot2]: public/images/shot2.png
[shot3]: public/images/shot3.png
