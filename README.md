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

![App start screen][shot]

## License

Unless stated otherwise within an embedded module, LGPLv3.

[shot]: public/images/shot.jpg